#!/usr/bin/env bash
# If you are executing this script in cron with a restricted environment,
# modify the shebang to specify appropriate path; /bin/bash in most distros.
# And, also if you aren't comfortable using(abuse?) env command.

# This script is based on https://serverfault.com/a/767079 posted
# by Mike Blackwell, modified to our needs. Credits to the author.

# This script is called from systemd unit file to mount or unmount
# a USB drive.

# PATH="$PATH:/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin:/bin:/sbin"

######################################################################
# Auxiliary functions

# Log a string via the syslog facility.
log()
{
    if [ $1 != debug ] || expr "$VERBOSE" : "[yY]" > /dev/null; then
        logger -p user.$1 -t "usb-mount[$$]" -- "$2"
    fi
}

usage()
{
    log info "Usage: $0 {add|remove} device_name (e.g. sdb1)"
    exit 1
}

if [[ $# -ne 2 ]]; then
    usage
fi

######################################################################
# Main program

VERBOSE=yes

ACTION=$1
DEVBASE=$2
DEVICE="/dev/${DEVBASE}"

# See if this drive is already mounted, and if so where
MOUNT_POINT=$(mount | grep ${DEVICE} | awk '{ print $3 }')

do_mount()
{
    if [[ -n ${MOUNT_POINT} ]]; then
        log error "Warning: ${DEVICE} is already mounted at ${MOUNT_POINT}"
        exit 1
    fi

################# NOTE THIS ONE =)))) IT'S SPECIFIC... #############
    MOUNT_POINT="/media/TRANSCEND"
    log debug "Mount point: ${MOUNT_POINT}"

    if grep -q " ${MOUNT_POINT} " /etc/mtab; then
        log error "Mount point ${MOUNT_POINT} already in use, exiting"
	exit 1
#        log info "Mount point ${MOUNT_POINT} already in use, make an unique one"
#        MOUNT_POINT+="-${DEVBASE}"
    fi
    mkdir -p ${MOUNT_POINT}

    # Global mount options
    OPTS="rw,relatime"

    if ! mount -o ${OPTS} ${DEVICE} ${MOUNT_POINT}; then
        log error "Error mounting ${DEVICE} (status = $?)"
        exit 1
    else
        # Track the mounted drives
        echo "${MOUNT_POINT}:${DEVBASE}" | cat >> "/var/log/usb-mount.track" 
    fi

    log info "Mounted ${DEVICE} at ${MOUNT_POINT}"
}

do_unmount()
{
    if [[ -z ${MOUNT_POINT} ]]; then
        log error "Warning: ${DEVICE} is not mounted"
	exit 1
    else
        umount -l ${DEVICE}
	log info "Unmounted ${DEVICE} from ${MOUNT_POINT}"
        sed -i.bak "\@${MOUNT_POINT}@d" /var/log/usb-mount.track
    fi
}

case "${ACTION}" in
    add)
        do_mount
        ;;
    remove)
        do_unmount
        ;;
    *)
        usage
        ;;
esac
