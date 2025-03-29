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
# shellcheck disable=SC2317

# Global Vars
TITLE="Sonar - A WiFi Keepalive daemon"

# Message Vars
SR_OK="\e[32mOK\e[0m"
SR_SK="\e[33mSKIPPED\e[0m"

### Global functions

### Messages
### Welcome Message
welcome_msg() {
    echo -e "${TITLE}\n"
    echo -e "\tSome Parts of the Uninstaller requires 'root' privileges."
    echo -e "\tYou will be prompted for your 'sudo' password, if needed.\n"
}

goodbye_msg() {
    echo -e "Please remove manually the 'sonar' folder in ${HOME}"
    echo -e "After that is done, please reboot!\nGoodBye...\n"
}

### General
## These two functions are reused from custompios common.sh
## Credits to guysoft!
## https://github.com/guysoft/CustomPiOS

install_cleanup_trap() {
    # kills all child processes of the current process on SIGINT or SIGTERM
    trap 'cleanup' SIGINT SIGTERM
}

cleanup() {
    # make sure that all child processed die when we die
    echo -e "Killed by user ...\r\nGoodBye ...\r"
    # shellcheck disable=2046
    [[ -n "$(jobs -pr)" ]] && kill $(jobs -pr) && sleep 5 && kill -9 $(jobs -pr)
}
##

err_exit() {
    if [[ "${1}" != "0" ]]; then
        echo -e "ERROR: Error ${1} occurred on line ${2}"
        echo -e "ERROR: Stopping $(basename "$0")."
        echo -e "Goodbye..."
    fi
    # shellcheck disable=2046
    [[ -n "$(jobs -pr)" ]] && kill $(jobs -pr) && sleep 5 && kill -9 $(jobs -pr)
    exit 1
}

### Init ERR Trap
trap 'err_exit $? $LINENO' ERR


### Uninstall sonar
ask_uninstall() {
    local remove
    read -erp "Do you REALLY want to remove existing 'sonar'? [y/N]: " -i "N" remove
    while true; do
        case "${remove}" in
            [yY]* )
                sudo echo -e "Password accepted!"
                break
            ;;
            [nN]* )
                echo -e "\nUninstall aborted by user! Exiting..."
                echo -e "GoodBye...\n"
                exit 1
            ;;
            *)
                echo -e "\nInvalid input, please try again."
            ;;
        esac
    done
}

uninstall_sonar() {
    local servicefile="/etc/systemd/system/sonar.service"
    local bin_path="/usr/local/bin/sonar"

    echo -e "Start uninstalling Sonar"

    if [[ -f "${servicefile}" ]]; then
        echo -en "Stopping sonar.service ...\r"
        sudo systemctl stop sonar.service &> /dev/null
        echo -e "Stopping sonar.service ... \t[${SR_OK}]\r"

        local envfile
        envfile=$(grep "EnvironmentFile=" "${servicefile}" | cut -d'=' -f2)

        if [[ -f "${envfile}" ]]; then
            local configfile
            configfile=$(grep "SONAR_ARGS=" "${envfile}" | sed -E 's/.*SONAR_ARGS="[^"]+ ([^"]+)".*/\1/')
            if [[ -f "${configfile}" ]]; then
                echo -en "Removing sonar.conf ...\r"
                sudo rm -f "${configfile}"
                echo -e "Removing sonar.conf ... [${SR_OK}]\r"
            else
                echo -e "Remove sonar.conf ... [${SR_SK}]"
            fi

            echo -en "Removing sonar.env ...\r"
            sudo rm -f "${envfile}"
            echo -e "Removing sonar.env ... [${SR_OK}]\r"
        else
            echo -e "Remove sonar.env ... [${SR_SK}]"
            echo -e "Remove sonar.conf ... [${SR_SK}]"
        fi

        echo -en "Uninstalling sonar.service ...\r"
        sudo rm -f "${servicefile}"
        echo -e "Uninstalling sonar.service...[${SR_OK}]\r"
    else
        echo -e "Sonar service file not found"
        echo -e "Remove sonar.service ... [${SR_SK}]"
        echo -e "Remove sonar.env ... [${SR_SK}]"
        echo -e "Remove sonar.conf ... [${SR_SK}]"
    fi

    echo -en "Removing legacy sonar binary ...\r"
    if [[ -f "${bin_path}" ]]; then
        sudo rm -f "${bin_path}"
        echo -e "Removing legacy sonar binary ... [${SR_OK}]"
    else
        echo -e "Removing legacy sonar binary ... [${SR_SK}]"
    fi
}

remove_logrotate() {
    local sonar_logrotate="/etc/logrotate.d/sonar"

    echo -en "Removing Logrotate Rule ...\r"
    if [[ -f "${sonar_logrotate}" ]]; then
        sudo rm -f "${sonar_logrotate}"
        echo -e "Removing Logrotate Rule ... [${SR_OK}]"
    else
        echo -e "Removing Logrotate Rule ... [${SR_SK}]"
    fi
}

remove_log_ln() {
    echo -en "Removing Log Symlink ...\r"
    local get_path
    get_path="$(find "${HOME}" -name "sonar.log" -type l)"
    if [[ -n "${get_path}" ]]; then
        sudo rm -f "${get_path}"
        echo -e "Removing Log Symlink ... [${SR_OK}]"
    else
        echo -e "Removing Log Symlink ... [${SR_SK}]"
    fi

    echo -en "Removing Log File ...\r"
    if [[ -f "/var/log/sonar.log" ]]; then
        sudo rm -f "/var/log/sonar.log"
        echo -e "Removing Log File ... [${SR_OK}]"
    else
        echo -e "Removing Log File ... [${SR_SK}]"
    fi
}

main() {
    install_cleanup_trap
    welcome_msg
    ask_uninstall
    uninstall_sonar
    remove_logrotate
    remove_log_ln
    goodbye_msg
}

main
exit 0
