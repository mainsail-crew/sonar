#!/usr/bin/env bash
#### Sonar - A WiFi Keepalive daemon
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2022
#### https://github.com/mainsail-crew/sonar
####
#### This File is distributed under GPLv3
####

# shellcheck enable=requires-variable-braces

# Global Vars
TITLE="Sonar - A WiFi Keepalive daemon"


### Non root
if [ ${UID} == '0' ]; then
    echo -e "DO NOT RUN THIS SCRIPT AS ROOT!\nExiting..."
    exit 1
fi

### noninteractive Check
if [ -z "${DEBIAN_FRONTEND}" ]; then
    export DEBIAN_FRONTEND=noninteractive
fi

### Functions

### Messages
# Welcome Message
function welcome_msg {
    echo -e "${TITLE}\n"
    echo -e "\tYou will be prompted for your 'sudo' password, if needed."
    echo -e "\tSome Parts of the Updater requires 'root' privileges."
    # Dirty hack to gain root permissions
    sudo echo -e "\n"
}

# Goodbye Message
function goodbye_msg {
    echo -e "\nInstallation complete.\n"
    echo -e "\tIn case something was updated:\n\tPlease reboot your machine!"
    echo -e "I hope you enjoy crowsnest, GoodBye ..."
}

### General
## These two functions are reused from custompios common.sh
## Credits to guysoft!
## https://github.com/guysoft/CustomPiOS

function install_cleanup_trap() {
    # kills all child processes of the current process on SIGINT or SIGTERM
    trap 'cleanup' SIGINT SIGTERM
}

function cleanup() {
    # make sure that all child processed die when we die
    echo -e "Killed by user ...\r\nGoodBye ...\r"
    # shellcheck disable=2046
    [ -n "$(jobs -pr)" ] && kill $(jobs -pr) && sleep 5 && kill -9 $(jobs -pr)
}

function err_exit {
    if [ "${1}" != "0" ]; then
        echo -e "ERROR: Error ${1} occured on line ${2}"
        echo -e "ERROR: Stopping $(basename "$0")."
        echo -e "Goodbye..."
    fi
    # shellcheck disable=2046
    [ -n "$(jobs -pr)" ] && kill $(jobs -pr) && sleep 5 && kill -9 $(jobs -pr)
    exit 1
}

### Init ERR Trap
trap 'err_exit $? $LINENO' ERR

# Helper funcs
function stop_sonar {
    if [ "$(sudo systemctl is-active sonar.service)" = "active" ]; then
        sudo systemctl stop sonar.service &> /dev/null
    fi
}

function start_sonar {
    if [ "$(sudo systemctl is-active sonar.service)" = "inactive" ]; then
        sudo systemctl start sonar.service &> /dev/null
    else
        if [ "$(sudo systemctl is-active sonar.service)" != "active" ]; then
            echo “sonar.service could not be started”
            echo “Try running \"sudo systemctl start sonar.service\" manually”
        fi
    fi
}

function daemon_reload {
    echo -en "Reload systemd to enable new deamon ...\r"
    sudo systemctl daemon-reload &> /dev/null
    echo -e "Reload systemd to enable new daemon ... [OK]"
}

function compare_files {
    local installed template
    installed="$(sha256sum "${1}" | awk '{print $1}')"
    template="$(sha256sum "${2}" | awk '{print $1}')"
    if [ -f "${1}" ] && [ "${installed}" != "${template}" ]; then
        echo "1"
    else
        echo "0"
    fi
}

# Copy Files funcs
function copy_service {
    local template origin
    origin="/etc/systemd/system/sonar.service"
    template="${PWD}/file_templates/sonar.service"
    if [ "$(compare_files "${origin}" "${template}")" -eq 1 ]; then
        echo -en "Copying sonar.service file ...\r"
        sudo cp -rf "${template}" "${origin}" > /dev/null
        echo -e "Copying sonar.service file ... [OK]\r"
        daemon_reload
    else
        echo -e "No update of '${origin}' required."
    fi
}

function copy_logrotate {
    local logrotatefile template origin
    origin="/etc/logrotate.d/sonar"
    logrotatefile="${PWD}/file_templates/logrotate_sonar"
    if [ "$(compare_files "${origin}" "${logrotatefile}")" -eq 1 ]; then
        echo -en "Copying logrotate file ...\r"
        sudo cp -rf "${logrotatefile}" "${origin}" > /dev/null
        echo -e "Copying logrotate file ... [OK]\r"
    else
        echo -e "No update of '${origin}' required."
    fi
}

function create_log_ln {
    local get_path
    get_path="$(find /home/ -name "klipper_logs")"
    if [ ! -h "${get_path}/sonar.log" ]; then
        ln -sf /var/log/sonar.log "${get_path}/sonar.log"
    fi
}

#### MAIN
install_cleanup_trap
welcome_msg
stop_sonar
copy_service
copy_logrotate
create_log_ln
start_sonar
goodbye_msg
exit 0
