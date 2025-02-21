#!/bin/bash

# stop the app running as systemd service
systemctl stopping myapp

# backup the existing config file
mv /etc/myapp/config.json /etc/myapp/config.json.bkup

# update the new config file
mv config.json /etc/myapp/config.json

systemctl start myapp

# verify the app is working fine
service_name="myapp"
if systemctl --quiet is-active "$service_name"; then
  echo "$service_name is running."
  # update success
  # clean up the backup and exit
  rm -f /etc/myapp/config.json.bkup
else
  echo "$service_name is not running."
  # update failed
  # restore from the backup
  mv /etc/myapp/config.json.bkup /etc/myapp/config.json
  # start the previous working version
  systemctl start myapp
fi
