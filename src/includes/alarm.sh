#!/bin/bash

###################################################################
# Script Author: Djordje Jocic                                    #
# Script Year: 2018                                               #
# Script License: MIT License (MIT)                               #
# =============================================================== #
# Personal Website: http://www.djordjejocic.com/                  #
# =============================================================== #
# Permission is hereby granted, free of charge, to any person     #
# obtaining a copy of this software and associated documentation  #
# files (the "Software"), to deal in the Software without         #
# restriction, including without limitation the rights to use,    #
# copy, modify, merge, publish, distribute, sublicense, and/or    #
# sell copies of the Software, and to permit persons to whom the  #
# Software is furnished to do so, subject to the following        #
# conditions.                                                     #
# --------------------------------------------------------------- #
# The above copyright notice and this permission notice shall be  #
# included in all copies or substantial portions of the Software. #
# --------------------------------------------------------------- #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, #
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND        #
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT     #
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,    #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, RISING     #
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR   #
# OTHER DEALINGS IN THE SOFTWARE.                                 #
###################################################################

#################
# GET FUNCTIONS #
#################

# GET FUNCTIONS GO HERE

#################
# SET FUNCTIONS #
#################

# GET FUNCTIONS GO HERE

##################
# CORE FUNCTIONS #
##################

# Creates an alarm based on the provided parameters.
# 
# @author: Djordje Jocic <office@djordjejocic.com>
# @copyright: 2018 MIT License (MIT)
# @version: 1.0.0
# 
# @param string $alarm_dir
#   Directory containing the alarm script.
# @param string $alarm_time
#   Countdown time that should be used, ex. <i>10s</i> or <i>15s,10s</i>.
# @param integer $alarm_delay
#   Countdown delay that should be used, ex. <i>10</i> for a 10s delay.
# @param string $alarm_message
#   Countdown message that should be used, ex. <i>renew the cert</i>.
# @param string $alarm_effect
#   Sound effect that should be used for an countdown.
# @param integer $alarm_volume
#   Master volume (percentage) that should be used during playback.
# @param string $alarm_command
#   Command that should be executed when an countdown is triggered.
# @return void

create_alarm()
{
    # Core Variables
    
    alarm_dir="$1";
    alarm_time="$2";
    alarm_delay="$3";
    alarm_message="$4";
    alarm_effect="$5";
    alarm_volume="$6";
    alarm_command="$7";
    
    # Cront Variables
    
    cron_details="";
    cron_task="";
    
    # Clock Variables
    
    clock_hour="";
    clock_minute="";
    clock_period="";
    
    # Other Variables
    
    alarm="";
    temp_file=$(mktemp);
    
    # Step 1 - Determine Clock Parameters
    
    clock_hour=$(echo "$alarm_time" | sed -n "1p");
    clock_minute=$(echo "$alarm_time" | sed -n "2p");
    clock_period=$(echo "$alarm_time" | sed -n "3p");
    
    # Step 2 - Print Notice
    
    printf "Creating an alarm that will trigger at %s:%s %s everyday...\n" "$clock_hour" "$clock_minute" "$clock_period";
    
    if [ ! -z "$alarm_message" ]; then
        printf "\nFollowing message will be shown: %s\n" "$alarm_message";
    fi
    
    # Step 3 -Get Crontab Details
    
    cron_details=$(crontab -l > "$temp_file" 2>&1 && cat "$temp_file");
    
    # Step 4 - Handle 12-Hour Clock
    
    clock_hour=$(echo "$clock_hour" | sed "s/^0//");
    clock_minute=$(echo "$clock_minute" | sed "s/^0//");
    
    if [ "$clock_period" = "PM" ]; then
        
        if [ "$clock_hour" = "12" ]; then
            clock_hour=0;
        else
            clock_hour=$(( clock_hour + 12 ));
        fi
        
    fi
    
    # Step 5 - Parse Cron Parameters
    
    alarm_dir=$(parse_value "$alarm_dir");
    alarm_effect=$(parse_value "$alarm_effect");
    alarm_message=$(parse_value "$alarm_message");
    alarm_command=$(parse_value "$alarm_command");
    
    # Step 6 - Generate Cron Task
    
    cron_task="$clock_minute $clock_hour * * * bash '$source_dir/alarm.sh' -t 0s";
    
    cron_task="$cron_task -s '$alarm_effect'";
    
    if [ $global_alarm = "yes" ]; then
        cron_task="$cron_task -g";
    fi
    
    if [ ! -z "$alarm_volume" ]; then
        cron_task="$cron_task -v '$alarm_volume'";
    fi
    
    if [ ! -z "$alarm_message" ]; then
        cron_task="$cron_task -m '$alarm_message'";
    fi
    
    if [ -z "$alarm_command" ]; then
        cron_task="$cron_task -c";
    else
        cron_task="$cron_task -c '$alarm_command'";
    fi
    
    # Step 7 - Add Cron Task
    
    cron_details="$cron_details\n$cron_task $alarm_mark";
    
    echo "$cron_details" | crontab;
}

# Lists available alarms.
# 
# @author: Djordje Jocic <office@djordjejocic.com>
# @copyright: 2018 MIT License (MIT)
# @version: 1.0.0
# 
# @return void

list_alarms()
{
    # Core Variables
    
    alarm="";
    alarm_hour="";
    alarm_minute="";
    alarm_period="";
    index=1;
    
    # Temp Variables
    
    temp="";
    temp_file=$(mktemp);
    
    # Step 1 - Gather Data
    
    crontab -l > "$temp_file" 2>&1;
    
    # Step 2 - Print Data
    
    if [ $(cat "$temp_file" | grep -c "$alarm_mark$") = "0" ]; then
        
        printf "No available alarms.\n";
        
    else
        
        printf "Available alarms:\n\n";
        
        while read alarm; do
            
            if [ ! -z $(echo "$alarm" | grep -oP "$alarm_mark$" | cut -c 1) ]; then
                
                temp=$(echo "$alarm" | grep -oP "^([0-9]+)\s([0-9]+)" | tr " " "\n");
                
                alarm_hour=$(echo "$temp" | sed -n 2p);
                alarm_minute=$(echo "$temp" | sed -n 1p);
                
                if [ "$alarm_hour" -lt "12" ]; then
                    
                    alarm_period="AM";
                    
                else
                    
                    alarm_hour=$(( clock_hour - 12 ));
                    alarm_period="PM";
                    
                fi
                
                printf "%02d. alarm: %02d:%02d %s\n" $index $alarm_hour $alarm_minute $alarm_period;
                
                index=$(( index + 1 ));
                
            fi
            
        done < $temp_file;
        
    fi
}

###################
# CHECK FUNCTIONS #
###################

# CHECK FUNCTIONS GO HERE

###################
# OTHER FUNCTIONS #
###################

# Resolves a provided sound effect ID and prints the path toward it.
# 
# @author: Djordje Jocic <office@djordjejocic.com>
# @copyright: 2018 MIT License (MIT)
# @version: 1.0.0
# 
# @param string $effect_id
#   ID of a sound effect that should be resolved.
# @return void

print_alarm_effect_path()
{
    # Core Variables
    
    effect_id=$1;
    
    # Logic
    
    case "$effect_id" in
        
        "")
            echo "$source_dir/effects/alarms/fire-alarm.wav";
        ;;
        
        "1")
            echo "$source_dir/effects/alarms/fire-alarm.wav";
        ;;
        
        "2")
            echo "$source_dir/effects/alarms/analogue-watch.wav";
        ;;
        
        "3")
            echo "$source_dir/effects/alarms/annoying-alarm.wav";
        ;;
        
    esac
}
