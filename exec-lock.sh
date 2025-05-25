#!/bin/sh
# ExecLock - Locks script when already running
# Copyright (C) 2025 https://github.com/mvin321
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

msg_logger () {
    sev_cd="$1"
    log_msg="$2"

    case "$sev_cd" in
        I)
            logger "$self [INFO]: $log_msg"    
            ;;
        W)
            logger "$self [WARNING]: $log_msg"    
            ;;
        E)
            logger "$self [ERROR]: $(cat $err_file)"
            ;;
    esac    
}

self=$(basename "$0") #This script's name

#Full path of the script to execute with locking
sh_full_path="$1" 

#Optional wait time in case another instance of the same script is running
wait_time="$2"

#Get base name of the target script
b_name=$(basename "$sh_full_path")

#Get directory of the target script
d_name=$(dirname "$sh_full_path") 

#Prepare error file
err_dir="$d_name/log"
mkdir -p "$err_dir"
err_file="$err_dir/exec-lock.$b_name.err"
echo -n > "$err_file" #create an empty file

#Check if script exists
if [ -f "$sh_full_path" ]; then
    alias=$(grep -oE "#SCRIPT-ALIAS:.*" "$sh_full_path" | awk 'NR==1 {print}' | awk -F: '{print $2}')
else
    echo "$sh_full_path: Does not exists." >> "$err_file"
    msg_logger "E"
    exit 1
fi

#Check if script is executable
if [ ! -x "$sh_full_path" ]; then
    echo "$sh_full_path: No exec permission." >> "$err_file"
    msg_logger "E"
    exit 1
fi

#Check if wait time is provided
valid_wait_time="0"
if [ -n "$wait_time" ]; then
    #Test if wait time provided is a number
    non_numerical=$(echo "$wait_time" | grep -E "[^0-9]")
    if [ -n "$non_numerical" ]; then
        valid_wait_time="1" #provided wait time is not a number
        wait_time="0"
    fi
else
    wait_time="0"
fi

#Set script name if alias is not available
if [ -z "$alias" ]; then
    alias="$b_name"
fi

#Check if there are other instances of the script running
pd=$(ps | grep "$b_name" | grep -vE "grep|$self") 

ctr=0
while [ "$ctr" -lt "$wait_time" ] && [ -n "$pd" ]; do
    pd=$(ps | grep "$b_name" | grep -vE "grep|$self") 

    if [ -z "$pd" ]; then
        delay_start="-- Waited ${ctr}s for prior instance to complete."
        break #exit loop
    fi
    sleep 1
    ctr=$(( ctr + 1 ))
done

#Run the script if all preliminary checks passed. Otherwise, skip
if [ -n "$pd" ]; then
    if [ "$wait_time" -gt 0 ]; then
        msg_logger "W" "$alias: Another instance of this script is still running after the maximum wait time (${wait_time}s). Skipping this execution."
    else
        msg_logger "W" "$sh_full_path: Already running. Skipping this execution."
    fi    
else
    startdttm=$(date)
    epoch_sdttm=$(date "+%s")
    logstart="$alias launched at $startdttm $delay_start"    
    msg_logger "I" "$logstart"

    $sh_full_path 2> "$err_file" 

    if [ "$?" -ne 0 ]; then
        msg_logger "E"
    fi

    enddttm=$(date)
    epoch_edttm=$(date "+%s")
    epoch_rtime=$(( epoch_edttm - epoch_sdttm ))
    min=$(( epoch_rtime / 60 ))
    sec=$(( epoch_rtime % 60 ))
    runtime="-- ${min} minute(s) ${sec} second(s)"

    logend="$alias    ended at $enddttm $runtime"
    msg_logger "I" "$logend"    
fi
