#!/usr/bin/env bash
#### Sonar - A WiFi Keepalive daemon
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2022
#### https://github.com/mainsail-crew/sonar
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

## disabeld SC2086 for some lines because there we want 'word splitting'

# Global Vars
TITLE="Sonar - A WiFi Keepalive daemon"

### Non root
if [ "${UNATTENDED}" == "false" ] && [ ${UID} == '0' ]; then
    echo -e "DO NOT RUN THIS SCRIPT AS ROOT!\nExiting..."
    exit 1
fi

### noninteractive Check
if [ -z "${DEBIAN_FRONTEND}" ]; then
    export DEBIAN_FRONTEND=noninteractive
fi

### Functions

### Messages
### Welcome Message
function welcome_msg {
    echo -e "${TITLE}\n"
    echo -e "\tSome Parts of the Installer requires 'root' privileges."
    echo -e "\tYou will be prompted for your 'sudo' password, if needed.\n"
}

function goodbye_msg {
    echo -e "\nInstallation complete.\n\tPlease reboot your machine!"
}

### Installer

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
##

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

function install_sonar {
    local servicefile logrotatefile bin_path sonar_bin
    bin_path="/usr/local/bin"
    sonar_bin="${HOME}/sonar/sonar"
    servicefile="${PWD}/file_templates/sonar.service"
    logrotatefile="${PWD}/file_templates/logrotate_sonar"
    moonraker_conf="${HOME}/klipper_config/moonraker.conf"
    moonraker_update="${PWD}/file_templates/moonraker_update.txt"
    echo -e "\nInstall Sonar Service ..."
    ## Install Dependencies
    echo -e "Installing 'sonar' Dependencies ..."
    # shellcheck disable=2086
    sudo apt install --yes --no-install-recommends crudini > /dev/null
    echo -e "Installing 'sonar' Dependencies ... [OK]"
    ## Link sonar to $PATH
    echo -en "Linking sonar ...\r"
    sudo ln -sf "${sonar_bin}" "${bin_path}" > /dev/null
    echo -e "Linking sonar ... [OK]\r"
    ## Copy sonar.service
    echo -en "Copying sonar.service file ...\r"
    sudo cp -rf "${servicefile}" /etc/systemd/system/sonar.service > /dev/null
    echo -e "Copying sonar.service file ... [OK]\r"
    ## Copy logrotate
    echo -en "Copying logrotate file ...\r"
    sudo cp -rf "${logrotatefile}" /etc/logrotate.d/sonar
    echo -e "Copying logrotate file ... [OK]\r"
    ## Link sonar.log to klipper_logs
    echo -en "Linking sonar.log ...\r"
    sudo ln -sf /var/log/sonar.log "${HOME}/klipper_logs/sonar.log" > /dev/null
    echo -e "Linking sonar.log ... [OK]\r"
    if [ "${UNATTENDED}" == "false" ]; then
        echo -en "Reload systemd to enable new deamon ...\r"
        sudo systemctl daemon-reload
        echo -e "Reload systemd to enable new daemon ... [OK]"
        echo -en "Enable sonar.service on boot ...\r"
        sudo systemctl enable sonar.service
        echo -e "Enable sonar.service on boot ... [OK]\r"
    fi
    if [ "${UNATTENDED}" == "true" ]; then
        echo -en "Adding Sonar Update Manager entry to moonraker.conf ...\r"
        cat "${moonraker_update}" >> "${moonraker_conf}"
        echo -e "Adding Sonar Update Manager entry to moonraker.conf ... [OK]"
    fi
}

#### MAIN
while getopts "z" arg; do
    case ${arg} in
        z)
            UNATTENDED="true"
            ;;
        *)
            UNATTENDED="false"
        ;;
    esac
done
install_cleanup_trap
welcome_msg
echo -e "Running apt update first ..."
sudo apt update
install_sonar
goodbye_msg
exit 0
