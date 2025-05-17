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

self=$(basename "$0") #This script's name

sh_full_path="$1" #Full path of the script to execute with locking

b_name=$(basename "$sh_full_path") #Remove directory and . prefix. Only retain script name
d_name=$(dirname "$sh_full_path") #Get the directory

startdttm=$(date)
epoch_sdttm=$(date -D "%a %b %d %T %Z %Y" -d "$startdttm" +%s)

[ -f "$sh_full_path" ]; f="$?" #Check if script exists

if [ "$f" -eq 0 ]; then
    alias=$(cat "$sh_full_path" | grep "SCRIPT-ALIAS" | awk 'NR==1 {print}' | awk -F: '{print $2}')
else
    alias="$b_name"
fi

logstart="$alias started at $startdttm"    
logger "$logstart"

#Prepare error file
err_dir="$d_name/log"
mkdir -p "$err_dir"
err_file="$err_dir/exec-lock.$b_name.err"
echo -n > "$err_file" #create an empty file

#Verify script validity
if [ "$f" -ne 0 ]; then
    echo "[ERROR] $self: $sh_full_path: Does not exists!" >> "$err_file"   
fi
[ -x "$sh_full_path" ]; x="$?" #Check if script is executable
if [ "$x" -ne 0 ]; then
    echo "[ERROR] $self: $sh_full_path: No exec permission!" >> "$err_file"
fi

#Verify that no instance of the script is currently running
pd=$(ps | grep "$b_name" | grep -vE "grep|$self") 

#Run the script if all preliminary checks are valid. Otherwise, skip
if [ ! -z "$pd" ]; then
    logger "[WARNING] $self: $sh_full_path: Already running.. skipping this one!"
    sh_stat="0"
else
    if [ "$x" -eq 0 ] && [ "$f" -eq 0 ]; then
        sh "$sh_full_path" 2> "$err_file" 
        sh_stat="$?"
    fi
fi

#if script failed, log error in syslog
if [ "$sh_stat" -ne 0 ] || [ "$x" -ne 0 ] || [ "$f" -ne 0 ]; then
    logger "[ERROR] $self: $(cat $err_file)"
fi

enddttm=$(date)
epoch_edttm=$(date -D "%a %b %d %T %Z %Y" -d "$enddttm" +%s)
epoch_rtime=$(( epoch_edttm - epoch_sdttm ))
min=$(( epoch_rtime / 60 ))
sec=$(( epoch_rtime % 60 ))
runtime="-- ${min} minute(s) ${sec} second(s)"

logend="$alias   ended at $enddttm $runtime"
logger "$logend"