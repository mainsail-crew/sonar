#!/usr/bin/env bash

#### get_config library

#### Sonar - A WiFi Keepalive daemon
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2022
#### https://github.com/mainsail-crew/sonar
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces


## Determine Configuration File and set defaults if not found.


function get_config_path {
    local dot_config_file new_path old_path
    dot_config_file="${BASE_SNR_PATH}/tools/.config"
    new_path="${BASE_USER_HOME}/printer_data/sonar.conf"
    old_path="${BASE_USER_HOME}/klipper_config/sonar.conf"

    debug_msg "${dot_config_file}"
    debug_msg "${new_path}"
    debug_msg "${old_path}"

    if [[ -f ${new_path} ]]; then
        echo "Hello"
    else
        exit 1
    fi

    # if [[ -e "${dot_config_file}" ]]; then
    #     # shellcheck disable=SC1090
    #     source "${dot_config_file}"
    #     if [[ -f "${SONAR_CONFIG_PATH}" ]]; then
    #         echo "${SONAR_CONFIG_PATH}"
    #     fi
    # elif [ -e "${new_path}" ]; then #&& [ ! -h "${new_path}" ]; then
    #     echo "${new_path}"
    # elif [[ -e "${old_path}" ]] && [[ ! -e "${new_path}" ]]; then
    #     echo "${old_path}"
    # fi
}
