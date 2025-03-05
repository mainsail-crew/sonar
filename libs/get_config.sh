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

set -Ee

## Determine Configuration File and set defaults if not found.

function get_config_path {
    # Check for path in .conf file first
    local dot_config_file="${BASE_SNR_PATH}/tools/.config"
    if [[ -f "${dot_config_file}" ]]; then
        # shellcheck disable=SC1090
        source "${dot_config_file}"
        if [[ -f "${SONAR_CONFIG_PATH}" ]]; then
            echo "${SONAR_CONFIG_PATH}"
            return
        fi
    fi

    # Check "new moonraker path"
    local new_path="${BASE_USER_HOME}/printer_data/config/sonar.conf"
    if [[ -f "${new_path}" ]]; then
        echo "${new_path}"
        return
    fi

    # Check "old moonraker path"
    local old_path="${BASE_USER_HOME}/klipper_config/sonar.conf"
    if [[ -f "${old_path}" ]]; then
        echo "${old_path}"
        return
    fi

    # Fallback Handling
    fallback_msg
    echo "${BASE_SNR_PATH}/resources/sonar.conf"
}
