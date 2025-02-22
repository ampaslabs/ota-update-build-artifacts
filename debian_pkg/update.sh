#!/bin/bash

#================================================
# MyApp Update Workflow Script - Example #1
#================================================

# backup the existing app
mv /usr/bin/myapp /usr/bin/myapp.bkup

# update the myapp package
sudo dpkg -i myapp_*.deb

# verify the app is working fine
service_name="myapp"
if systemctl --quiet is-active "$service_name"; then
  echo "$service_name is running."
  # update success
  # clean up the backup and exit
  rm -f /usr/bin/myapp.bkup
else
  echo "$service_name is not running."
  # update failed
  # restore from the backup
  mv /usr/bin/myapp.bkup /usr/bin/myapp
  # start the previous working version
  systemctl start myapp
fi
