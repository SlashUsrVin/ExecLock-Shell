# ExecLock
A launcher script that prevents concurrent execution of a program. If another instance is already running, it skips launching a new one—unless a wait time is specified. Start time, end time, and any warnings and errors encountered are logged to syslog (/tmp/syslog.log). 

## Usage:
__/jffs/scripts/exec-lock.sh__ _[script to run]_ _[optional wait period in seconds]_  

    /jffs/scripts/exec-lock.sh /jffs/scripts/cake-connmark/cake-connmark.sh 30

## Syslog Sample Messages:  
__ERROR__

    May 25 22:00:00 SlashUsrVin: exec-lock.sh [ERROR]: /jffs/scripts/cake-connmark/cake-connmark.sh: Does not exists.
    May 25 22:05:00 SlashUsrVin: exec-lock.sh [ERROR]: /jffs/scripts/cake-connmark/cake-connmark.sh: No exec permission.
    
__WARNING__
    
   _If wait time is NOT provided_
    
    May 25 22:11:32 SlashUsrVin: exec-lock.sh [WARNING]: /jffs/scripts/cake-connmark/cake-connmark.sh: Already running. Skipping this execution.

   _If wait time is provided_
    
    May 25 22:11:32 SlashUsrVin: exec-lock.sh [WARNING]: /jffs/scripts/cake-connmark/cake-connmark.sh: Another instance of this script is still running after the maximum wait time (5s). Skipping this execution.

__INFO__  

   _If wait time is provided_
    
    May 25 22:15:17 SlashUsrVin: exec-lock.sh [INFO]: CAKE-ConnMark launched at Sun May 25 22:15:17 CST 2025 -- Waited 6s for prior instance to complete.
    May 25 22:15:27 SlashUsrVin: exec-lock.sh [INFO]: CAKE-ConnMark    ended at Sun May 25 22:15:27 CST 2025 -- 0 minute(s) 10 second(s)

   _Normal run - without conflict_
   
    May 25 21:58:00 SlashUsrVin: exec-lock.sh [INFO]: CAKE-ConnMark launched at Sun May 25 21:48:00 GMT 2025
    May 25 21:58:02 SlashUsrVin: exec-lock.sh [INFO]: CAKE-ConnMark    ended at Sun May 25 21:48:02 GMT 2025 -- 0 minute(s) 2 second(s)

## Script Alias (optional):
exec-lock.sh scans the target script for a #SCRIPT-ALIAS:[alias] comment and uses the alias in syslog entries instead of the actual script name. 

For example, if cake-connmark.sh contains #SCRIPT-ALIAS:CAKE-ConnMark, that alias will appear in the syslog logs:

    May 25 21:58:00 SlashUsrVin: exec-lock.sh [INFO]: CAKE-ConnMark launched at Sun May 25 21:48:00 GMT 2025
    May 25 21:58:02 SlashUsrVin: exec-lock.sh [INFO]: CAKE-ConnMark    ended at Sun May 25 21:48:02 GMT 2025 -- 0 minute(s) 2 second(s)

When script has no alias:

    May 25 21:58:00 SlashUsrVin: exec-lock.sh [INFO]: cake-connmark.sh launched at Sun May 25 21:48:00 GMT 2025
    May 25 21:58:02 SlashUsrVin: exec-lock.sh [INFO]: cake-connmark.sh    ended at Sun May 25 21:48:02 GMT 2025 -- 0 minute(s) 2 second(s)