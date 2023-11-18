#!/usr/bin/env bash
# If you are executing this script in cron with a restricted environment,
# modify the shebang to specify appropriate path; /bin/bash in most distros.
# And, also if you aren't comfortable using(abuse?) env command.
#PATH="$PATH:/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin:/bin:/sbin"

sudo cp ./usb-mount.sh /usr/local/bin/
sudo chmod 755 /usr/local/bin/usb-mount.sh

# Systemd unit file for USB automount/unmount 
sudo cp ./usb-mount@.service /etc/systemd/system/usb-mount@.service

# Create udev rule to start/stop usb-mount@.service on hotplug/unplug
sudo cat ./99-local.rules.usb-mount >> /etc/udev/rules.d/99-local.rules

sudo systemctl daemon-reload
sudo udevadm control --reload-rules
sudo service udev restart
