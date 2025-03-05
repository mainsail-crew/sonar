#!/usr/bin/env bash

#### Logging library

#### Sonar - A WiFi Keepalive daemon
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2022
#### https://github.com/mainsail-crew/sonar
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

# Exit on Errors
set -Ee

## Logging
function debug_log {
    get_param sonar debug_log 2> /dev/null || echo "false"
}

function init_log_entry {
    log_msg "INFO: Sonar - A WiFi Keepalive daemon"
    log_msg "INFO: Version: ${SNR_LOCAL_VERSION}"
    log_msg "INFO: Prepare Startup ..."
    # print config when debug_log is set
    [[ "$(debug_log)" != "false" ]] && print_cfg
}

function print_cfg {
    local prefix="\t\t"
    log_msg "INFO: Print Configfile: '$(get_config_path)'"

    while read -r line; do
        local strip
        # remove comments
        strip=$(echo "${line}" | sed 's/^##.*//g;s/#[[:space:]].*//g')

        # only print non-empty lines
        [[ -n "${strip}" ]] && log_msg "${prefix}${strip}"
    done < "$(get_config_path)"
}

function log_msg {
    local msg="${1}"
    echo -e "${msg}"

    # Stop here if no persistant log is set
    [[ "${SNR_PERSISTANT_LOG}" != "true" ]] && return

    # make sure file exists
    [[ ! -f "${SNR_LOG_PATH}" ]] && touch "${SNR_LOG_PATH}"

    # write to logfile with timestamp
    echo -e "$(date +'[%D %T]') ${msg}" | tr -s ' ' >> "${SNR_LOG_PATH}" 2>&1
}
