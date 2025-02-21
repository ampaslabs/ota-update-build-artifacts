#!/bin/sh

#================================================
# MyApp Update Workflow Script - Example #2
# MyApp is stored in the AWS S3 Storage
#================================================

# On-failure (before the backup) just restore the service
invoke_restore() {
    systemctl start myapp
    systemctl status myapp
    exit 1
}
# On-failure clean up and restore from backup.
invoke_restore_backup() {
    systemctl stop myapp
    cp /usr/local/bin/myapp.bkup /usr/local/bin/myapp
    cp -R /var/lib/myapp.bkup /var/lib/myapp
    rm -rf /var/lib/myapp.bkup
    cp /etc/myapp/config.json.bkup /etc/myapp/config.json   
    systemctl start myapp
    systemctl status myapp
    exit 1
}

debug_error() {
    echo "$(date +"%Y-%m-%d %H:%M:%S.%N"): Error: $1"
}

debug_log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S.%N"): $1"
}

# Workflow Begins.

# stop the service first
systemctl stop myapp

# backup the current working app 
cp /usr/local/bin/myapp /usr/local/bin/myapp.bkup
if [ $? -eq 0 ]; then
    debug_log "Binary copied."
else 
    debug_error "Binary backup failed."
    invoke_restore
fi

# backup the current config file
cp /etc/myapp/config.json /etc/myapp/config.json.bkup
if [ $? -eq 0 ]; then
    debug_log "Config copied."
else 
    debug_error "Config backup failed."
    invoke_restore
fi

# Download the new myapp file from your online storage such as AWS S3 Bucket
curl -O https://abcdefghxyz.amazonaws.com/v41/bin/myapp && chmod +wx myapp && sudo mv myapp /usr/local/bin
if [ $? -eq 0 ]; then
    debug_log "New binary downloaded."
else 
    debug_error "New binary download failed."
    invoke_restore_backup
fi

# Download a new myapp config.json file from your online storage such as AWS S3 Bucket
curl -O https://abcdefghxyz.amazonaws.com/v41/cfg/config.json && sudo mv config.json /etc/myapp/config.json
if [ $? -eq 0 ]; then
    debug_log "New config file downloaded."
else 
    debug_error "New config file download failed."
    invoke_restore_backup
fi

# Start the service again
systemctl start myapp

# Check the status of the service
STATUS="$(systemctl status myapp | grep 'Active: active (running)')"
if [ -z $STATUS ]; then
    debug_error "myapp service failed to run."
    invoke_restore_backup
else 
    debug_log "myapp service is running."
fi

# Clean up files
rm -f /usr/local/bin/myapp.bkup
rm -f /etc/myapp/config.json.bkup