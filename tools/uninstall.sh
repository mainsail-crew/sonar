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

# Global Vars
TITLE="Sonar - A WiFi Keepalive daemon"

### Functions

### Messages
### Welcome Message
function welcome_msg {
    echo -e "${TITLE}\n"
    echo -e "\tSome Parts of the Uninstaller requires 'root' privileges."
    echo -e "\tYou will be prompted for your 'sudo' password, if needed.\n"
}

function goodbye_msg {
    echo -e "Please remove manually the 'sonar' folder in ${HOME}"
    echo -e "After that is done, please reboot!\nGoodBye...\n"
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


### Uninstall sonar
function ask_uninstall {
    local remove
    if [ -d "${HOME}/sonar" ]; then
        read -rp "Do you REALLY want to remove existing 'sonar'? (YES/NO) " remove
        if [ "${remove}" = "YES" ]; then
            sudo echo -e "\nPlease enter your password!"
            uninstall_sonar
            remove_logrotate
            remove_log_ln
            goodbye_msg
        else
            echo -e "\nYou answered '${remove}'! Uninstall will be aborted..."
            echo -e "GoodBye...\n"
            exit 1
        fi
    else
        echo -e "\n'sonar' seems not installed."
        echo -e "Exiting. GoodBye ..."
    fi
}

function uninstall_sonar {
    local servicefile bin_path
    servicefile="/etc/systemd/system/sonar.service"
    bin_path="/usr/local/bin/sonar"
    echo -en "\nStopping sonar.service ...\r"
    sudo systemctl stop sonar.service &> /dev/null
    echo -e "Stopping sonar.service ... \t[OK]\r"
    echo -en "Uninstalling sonar.service...\r"
    if [ -f "${servicefile}" ]; then
        sudo rm -f "${servicefile}"
    fi
    if [ -x "${bin_path}" ]; then
        sudo rm -f "${bin_path}"
    fi
    echo -e "Uninstalling sonar.service...[OK]\r"
}

function remove_logrotate {
    echo -en "Removing Logrotate Rule ...\r"
    sudo rm -f /etc/logrotate.d/sonar
    echo -e "Removing Logrotate Rule ... [OK]"
}

function remove_log_ln {
    local get_path
    get_path="$(find /home/ -name "klipper_logs")"
    if [ -h "${get_path}/sonar.log" ]; then
        rm -f /var/log/sonar.log "${get_path}/sonar.log"
    fi
}

#### MAIN
install_cleanup_trap
welcome_msg
ask_uninstall

exit 0
