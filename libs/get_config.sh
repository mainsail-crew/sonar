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
    local dot_config_file old_path new_path
    dot_config_file="${BASE_SNR_PATH}/tools/.config"
    old_path="${BASE_USER_HOME}/klipper_config/sonar.conf"
    new_path="${BASE_USER_HOME}/printer_data/sonar.conf"

    if [[ -f "${dot_config_file}" ]]; then
        # shellcheck disable=SC1090
        source "${dot_config_file}"
        if [[ -f "${SONAR_CONFIG_PATH}" ]]; then
            echo "${SONAR_CONFIG_PATH}"
        fi
        return
    fi
    if [[ -f "${new_path}" ]] && [[ ! -h "${new_path}" ]]; then
        echo "${new_path}"
        return
    fi
    if [[ -f "${old_path}" ]] && [[ ! -f "${new_path}" ]]; then
        echo "${old_path}"
        return
    fi
}

debug_msg "Config File location: $(get_config_path)"
