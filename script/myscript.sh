#!/bin/bash

# check if the app is working fine
service_name="myapp"
if systemctl --quiet is-active "$service_name"; then
  echo "$service_name is running."
else
  echo "$service_name is not running."
fi