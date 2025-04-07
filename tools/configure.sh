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

# Exit on errors
set -Ee

# Debug
# set -x

### Non root
if [[ ${UID} == '0' ]]; then
    echo -e "DO NOT RUN AS ROOT!\nExiting..."
    exit 1
fi

# Global Vars
SR_CONFIG_USER=$(whoami)
SR_CONFIG_CONFIGFILE="tools/.config"
SR_CONFIG_ROOTPATH="/home/${SR_CONFIG_USER}/printer_data"

### Messages
header_msg() {
    clear
    echo -e "\e[34m\n #### Sonar Install Configurator ####\e[0m\n"
}

welcome_msg() {
    header_msg
    echo -e "This will guide you through install configuration"
    echo -e "After successful configuration use\n"
    echo -e "\t\e[32msudo make install\e[0m\n"
    echo -e "to install Sonar ..."
}

abort_msg() {
    header_msg
    echo -e "Configuration aborted by user ... \e[31mExiting!\e[0m"
}

check_config_file_msg() {
    header_msg
    echo -e "\n\t\e[33mWarning:\e[0m Found an existing .config!\n"
}


default_path_msg() {
    echo -e "Hit ENTER to use default."
}

data_path_msg() {
    header_msg
    echo -e "Please specify path for printer_data directory\n"
    echo -e "\t\e[34mNOTE:\e[0m Skip trailing backslash!"
    echo -e "\tDefault: \e[32m${SR_CONFIG_ROOTPATH}\e[0m\n"
}

add_moonraker_entry_msg() {
    header_msg
    echo -e "Should the update_manager entry added to your moonraker.conf?\n"
    echo -e "\t\e[34mNOTE:\e[0m\n\tThis will only work if your moonraker.conf"
    echo -e "\tshares the same path as your Sonar.conf!!!\n"
    echo -e "If you want/have to do that manually,\nplease see 'resources/moonraker_update.txt'"
    echo -e "Copy the content in your moonraker.conf\n"
}

goodbye_msg() {
    header_msg
    echo -e "\t\e[32mSuccessful\e[0m configuration."
    echo -e "\tIn order to install Sonar, please run:\n"
    echo -e "\t\t\e[32msudo make install\e[0m\n"
    echo -e "Goodbye ..."
}

### funcs
continue_config() {
    local reply
    while true; do
        read -erp "Continue? [Y/n]: " -i "Y" reply
        case "${reply}" in
            [Yy]* )
                break
            ;;
            [Nn]* )
                abort_msg
                exit 0
            ;;
            * )
                echo -e "\e[31mERROR: Please type Y or N !\e[0m"
            ;;
        esac
    done
}

check_config_file() {
    local reply
    if [[ -f "${SR_CONFIG_CONFIGFILE}" ]]; then
        check_config_file_msg
        while true; do
            read -erp "Overwrite? [y/N]: " -i "N" reply
            case "${reply}" in
                [Yy]* )
                    rm -f tools/.config
                    break
                ;;
                [Nn]* )
                    abort_msg
                    exit 0
                ;;
                * )
                    echo -e "\e[31mERROR:\e[0m Please type Y or N !"
                ;;
            esac
        done
        return 0
    fi
    return 0
}

create_config_header() {
    echo -e "BASE_USER=\"${SR_CONFIG_USER}\"" >> "${SR_CONFIG_CONFIGFILE}"
}

specify_data_path() {
    local reply
    data_path_msg
    default_path_msg
    read -erp "Please enter path: " reply

    if [[ -n "${reply}" ]]; then
        SR_CONFIG_ROOTPATH=${reply}
    fi

    echo -e "SONAR_DATA_PATH=\"${SR_CONFIG_ROOTPATH}\"" >> "${SR_CONFIG_CONFIGFILE}"
}

add_moonraker_entry() {
    local reply
    add_moonraker_entry_msg
    while true; do
        read -erp "Add update_manager entry? [Y/n]: " -i "Y" reply
        case "${reply}" in
            [yY]*)
                echo -e "SONAR_ADD_SONAR_MOONRAKER=\"1\"" >> "${SR_CONFIG_CONFIGFILE}"
                break
            ;;
            [nN]*)
                echo -e "SONAR_ADD_SONAR_MOONRAKER=\"0\"" >> "${SR_CONFIG_CONFIGFILE}"
                break
            ;;
            * )
                    echo -e "\e[31mERROR:\e[0m Please type Y or N !"
            ;;
        esac
    done
}

### Main func
main() {
    welcome_msg
    continue_config
    check_config_file

    create_config_header
    specify_data_path
    add_moonraker_entry

    goodbye_msg
}

### MAIN
main
exit 0
