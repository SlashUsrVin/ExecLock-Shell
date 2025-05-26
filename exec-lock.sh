#!/bin/sh
# ExecLock - Locks a script when already running
# Author: SlashUsrVin
#
# MIT License
# Copyright (c) 2025 SlashUsrVin
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# See the LICENSE file in the repository root for full text.

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
