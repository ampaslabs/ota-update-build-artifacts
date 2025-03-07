#!/bin/bash

#================================================
# Firmware Update Workflow Script
#================================================

# The script implements A/B system update with U-Boot boatloader.
# U-Boot's "bootcmd" should refer to the "bootpart" variable to decide
# which boot partition to boot from.
# Performs healthcheck and rollback on failure.

# Configuration
NEW_ROOTFS_IMAGE="$1"
ROOTFS_A="/dev/mmcblk0p2"
ROOTFS_B="/dev/mmcblk0p3"
TEMP_IMAGE="/tmp/new_rootfs.img"
MOUNT_POINT="/mnt/new_rootfs"
HEALTH_CHECK_SCRIPT="/etc/init.d/health_check.sh"
UBOOT_BOOT_PART_VAR="bootpart"
UBOOT_BOOT_COUNT_VAR="bootcount"
UBOOT_BOOT_LIMIT="3"
UBOOT_PART_A_VALUE="1"
UBOOT_PART_B_VALUE="2"

# Function to get current boot partition
get_current_boot_part() {
  local bootpart=$(fw_printenv "$UBOOT_BOOT_PART_VAR" | awk -F '=' '{print $2}')
  echo "$bootpart"
}

# Function to set boot partition
set_boot_part() {
  local part_value="$1"
  fw_setenv "$UBOOT_BOOT_PART_VAR" "$part_value"
}

# Function to reset boot count
reset_boot_count() {
  fw_setenv "$UBOOT_BOOT_COUNT_VAR" "0"
}

# Function to switch boot partition
switch_boot_part() {
  local current_part=$(get_current_boot_part)
  if [ "$current_part" == "$UBOOT_PART_A_VALUE" ]; then
    set_boot_part "$UBOOT_PART_B_VALUE"
  else
    set_boot_part "$UBOOT_PART_A_VALUE"
  fi
  reset_boot_count
}

# Main update process
echo "$(date) - Starting OTA update..."

# Download the new rootfs image
echo "$(date) - Downloading image from $NEW_ROOTFS_IMAGE..."
curl -s -o "$TEMP_IMAGE" "$NEW_ROOTFS_IMAGE"
if [ $? -ne 0 ]; then
  echo "$(date) - Error downloading image."
  rm "$TEMP_IMAGE"
  exit 1
fi

# Download the checksum file
echo "$(date) - Downloading checksum file..."
curl -s -o "$CHECKSUM_FILE" "${NEW_ROOTFS_IMAGE}.sha256"
if [ $? -ne 0 ]; then
  echo "$(date) - Error downloading checksum file."
  rm "$TEMP_IMAGE"
  rm "$CHECKSUM_FILE"
  exit 1
fi

# Verify checksum
echo "$(date) - Verifying checksum..."
if ! sha256sum -c "$CHECKSUM_FILE" 2>/dev/null | grep -q "OK"; then
  echo "$(date) - Checksum verification failed."
  rm "$TEMP_IMAGE"
  rm "$CHECKSUM_FILE"
  exit 1
fi

# Determine the target partition
local current_part=$(get_current_boot_part)
if [ "$current_part" == "$UBOOT_PART_A_VALUE" ]; then
  TARGET_ROOTFS="$ROOTFS_B"
else
  TARGET_ROOTFS="$ROOTFS_A"
fi

# Unmount target rootfs if mounted.
if mount | grep "$TARGET_ROOTFS" ; then
        umount "$TARGET_ROOTFS"
fi

# Write the new image to the target partition
echo "$(date) - Writing image to $TARGET_ROOTFS..."
dd if="$TEMP_IMAGE" of="$TARGET_ROOTFS" bs=4M status=progress
if [ $? -ne 0 ]; then
  echo "$(date) - Error writing image to $TARGET_ROOTFS."
  rm "$TEMP_IMAGE"
  rm "$CHECKSUM_FILE"
  exit 1
fi

# Clean up the downloaded image and checksum file
rm "$TEMP_IMAGE"
rm "$CHECKSUM_FILE"


# Mount the new rootfs to copy health check script
mkdir -p "$MOUNT_POINT"
mount "$TARGET_ROOTFS" "$MOUNT_POINT"
if [ $? -ne 0 ]; then
        echo "$(date) - Failed to mount $TARGET_ROOTFS"
        exit 1
fi

# Copy health check script to the new rootfs
cat <<EOF > "$MOUNT_POINT$HEALTH_CHECK_SCRIPT"
#!/bin/bash

# Configuration
UBOOT_BOOT_COUNT_VAR="bootcount"
UBOOT_BOOT_LIMIT="3"

# Function to get current boot count
get_boot_count() {
  fw_printenv "\$UBOOT_BOOT_COUNT_VAR" | awk -F '=' '{print \$2}'
}

# Function to increment boot count
increment_boot_count() {
  local current_count=\$(get_boot_count)
  local new_count=\$((\$current_count + 1))
  fw_setenv "\$UBOOT_BOOT_COUNT_VAR" "\$new_count"
}

# Function to switch boot partition (rollback)
switch_boot_part() {
  local current_part=\$(fw_printenv "bootpart" | awk -F '=' '{print \$2}')
  if [ "\$current_part" == "1" ]; then
    fw_setenv "bootpart" "2"
  else
    fw_setenv "bootpart" "1"
  fi
  fw_setenv "\$UBOOT_BOOT_COUNT_VAR" "0"
}

# Main health check logic
sleep 60
ping -c 1 google.com > /dev/null
if [ \$? -ne 0 ]; then
  echo "\$(date) - Health check failed."
  increment_boot_count

  local current_count=\$(get_boot_count)
  if [ "\$current_count" -ge "\$UBOOT_BOOT_LIMIT" ]; then
    echo "\$(date) - Boot limit reached. Triggering rollback."
    switch_boot_part
    reboot
  else
    echo "\$(date) - Boot count incremented. Rebooting."
    reboot
  fi
else
  echo "\$(date) - Health check successful. Resetting boot count."
  fw_setenv "\$UBOOT_BOOT_COUNT_VAR" "0"
  rm /etc/init.d/health_check.sh # Remove health check script
  exit 0
fi
EOF

chmod +x "$MOUNT_POINT$HEALTH_CHECK_SCRIPT"
umount "$MOUNT_POINT"
rmdir "$MOUNT_POINT"

# Switch boot to the new rootfs
switch_boot_part

# Reboot to load the new rootfs
reboot