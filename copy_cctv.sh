#!/bin/bash

date=$(date '+%Y-%m-%d')
cur_date=$(date '+%Y-%m-%d-%H:%M')
base_path="/var/cache/zoneminder/events"
local_dir1="$base_path/1/$date/"
local_dir2="$base_path/2/$date/"
local_dir3="$base_path/3/$date/"
remote_dir="/mnt/van/cctv/"
remote_ip="100.119.167.121"

file1=$(ls -t $local_dir1 | head -n1)
file2=$(ls -t $local_dir2 | head -n1)
file3=$(ls -t $local_dir3 | head -n1)

logfile="/tmp/cctv_copy.log"

instance_count=$(pgrep -c -f copy_cctv.sh)

files=("$local_dir1$file1" "$local_dir2$file2" "$local_dir3$file3")
remote_contents=$(ssh andy@$remote_ip 'ls /mnt/van/cctv')

cur_date () {
	echo "["$(date '+%Y-%m-%d-%H:%M:%S')"]"
}

run_id="run_$RANDOM"

echo "$(cur_date) Checking ccty_copy not already running" >> $logfile

if [ "$instance_count" -gt 5 ]; then
    echo "$(cur_date) cctv_copy already running, not starting" >> $logfile
else    
    echo "$(cur_date) STARTING $run_id" >> $logfile
    
    for item in "${files[@]}"; do
    
        file_name=$(echo "$item" | sed 's/\//-/g' |cut -d "-" -f6,7,8,9,10,11,12)
        archive_name="cam-0$file_name.tar.gz"
    
        echo "$(cur_date) Current archive is $archive_name checking on remote" >> $logfile
            if printf '%s\n' "${remote_contents[@]}" | grep -q -F "$archive_name"; then
    	    echo "$(cur_date) Match found for: $archive_name updating local archive" >> $logfile
                tar -czvf /tmp/$archive_name $item > /dev/null 2>&1
    	    echo "$(cur_date) Match found for: $archive_name rsyncing archive to remote" >> $logfile
    	    rsync -az /tmp/$archive_name andy@$remote_ip:$remote_dir$archive_name
    	    echo "$(cur_date) Removing local archive $archive_name" >> $logfile
    	    rm -f /tmp/$archive_name
    	    echo "$(cur_date) $archive_name removed" >> $logfile
            else
                echo "$(cur_date) Match not found for $archive_name copying to remote" >> $logfile
                tar -czvf /tmp/$archive_name $item > /dev/null 2>&1
                scp /tmp/$archive_name andy@$remote_ip:$remote_dir$archive_name
    	    echo "$(cur_date) Copying $archive_name complete" >> $logfile
    	    echo "$(cur_date) Removing local archive $archive_name" >> $logfile
    	    rm -f /tmp/$archive_name
    	    echo "$(cur_date) $archive_name removed" >> $logfile
            fi
    done
    
    wait
    
    echo "$(cur_date) FINISHED $run_id" >> $logfile
    echo "" >> $logfile
fi
