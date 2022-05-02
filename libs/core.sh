#!/bin/env bash
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

## Version of webcamd
function self_version {
    pushd "${BASE_SNR_PATH}" &> /dev/null || exit 1
    git describe --always --tags 2> /dev/null || echo "unknown"
    popd &> /dev/null || exit 1
}

# Init Traps
trap 'shutdown' 1 2 3 15
trap 'err_exit $? $LINENO' ERR

# Behavior of traps
# and kill running jobs
function err_exit {
    if [ "${1}" != "0" ]; then
        log_msg "ERROR: Error ${1} occured on line ${2}"
        log_msg "ERROR: Stopping $(basename "$0")."
        log_msg "Goodbye ..."
    fi
    exit 1
}

# Print Goodbye Message
# and kill running jobs
function shutdown {
    log_msg "Sonar service stopped or killed ..."
    if [ -n "$(jobs -pr)" ]; then
        jobs -pr | while IFS='' read -r job_id; do
            kill "${job_id}"
        done
    fi
    log_msg "Goodbye ..."
    exit 0
}

# Service disabled by user
function enable_service {
    local config service
    config="${BASE_USER_HOME}/klipper_config/sonar.conf"
    service="$(get_param sonar enable)"
    if [ -f "${config}" ] && [ "${service}" == "false" ]; then
        log_msg "Sonar.service disabled by user configuration"
        log_msg "Service will be halted until next reboot"
        systemctl stop sonar.service
    fi
}

## Sanity Checks
# Check for config file
function check_cfg {
    local config
    config="${BASE_USER_HOME}/klipper_config/sonar.conf"
    if [ -z "${SONAR_CFG}" ] &&
    [ -f "${config}" ]; then
        SONAR_CFG="${config}"
        log_msg "INFO: Found config file ${SONAR_CFG}, import settings."
        print_cfg
        setup_user_conf
    else
        log_msg "INFO: No config file found, using defaults."
        setup_defaults
    fi
}

# Dependency Check
# call check_dep <programm>, ex.: check_dep vim
function check_dep {
    local dep
    dep="$(whereis "${1}" | awk '{print $2}')"
    if [ -z "${dep}" ]; then
        log_msg "Dependency: '${1}' not found. Exiting!"
        exit 1
    else
        log_msg "Dependency: '${1}' found in ${dep}."
    fi
}

# Check all needed Dependencies
function initial_check {
    log_msg "INFO: Checking Dependencys"
    check_dep "crudini"
    check_dep "logger"
    check_cfg
    check_eth_con
    enable_service
}

# Check if eth0 is used.
function check_eth_con {
    if [ -f "/sys/class/net/eth0/operstate" ] &&
    [ "$(cat /sys/class/net/eth0/operstate)" == "up" ]; then
        log_msg "WARN: Connected via ethernet, please disable service ..."
        log_msg "Stopping sonar.service till next reboot ..."
        systemctl stop sonar.service
    fi
}

# get default gw
function get_def_gw {
    local default_gw
    if [ "$(cat /sys/class/net/wlan0/operstate)" == "up" ]; then
        default_gw="$(ip route | awk 'NR==1 {print $3}')"
        echo "${default_gw}"
    fi
}

# default settings
function setup_defaults {
    SONAR_TARGET="$(get_def_gw)"
    export SONAR_TARGET
    export SONAR_PING_COUNT="3"
    export SONAR_CHECK_INTERVAL="60"
    export SONAR_RESTART_TRESHOLD="10"
}

# setup user config
function setup_user_conf {
    local target count interval treshold
    target=$(get_param sonar target)
    count=$(get_param sonar count)
    interval=$(get_param sonar interval)
    treshold=$(get_param sonar restart_treshold)
    if [ "${target}" == "auto" ]; then
        SONAR_TARGET="$(get_def_gw)"
        export SONAR_TARGET
    else
        export SONAR_TARGET="${target}"
    fi
    # using defaults if empty
    if [ -n "${count}" ]; then
        export SONAR_PING_COUNT="${count}"
    else
        export SONAR_PING_COUNT="3"
    fi
    if [ -n "${interval}" ]; then
        export SONAR_CHECK_INTERVAL="${interval}"
    else
        export SONAR_CHECK_INTERVAL="60"
    fi
    if [ -n "${treshold}" ]; then
        export SONAR_RESTART_TRESHOLD="${treshold}"
    else
        export SONAR_RESTART_TRESHOLD="10"
    fi
}

function check_connection {
    ping -D -c"${SONAR_PING_COUNT}" "${SONAR_TARGET}" 2> /dev/null | \
    tail -n1 | sed 's/rtt/Triptime:/'
}

function keepalive {
    local triptime
    triptime="$(check_connection)"
    if [ -n "${triptime}" ]; then
        if [ "$(debug_log)" == "true" ]; then
            log_msg "Reached ${SONAR_TARGET}, ${triptime}"
        fi
    else
        log_msg "Connection lost, ${SONAR_TARGET} not reachable!"
        log_msg "Restarting network in ${SONAR_RESTART_TRESHOLD} seconds."
        ifconfig wlan0 down
        sleep "${SONAR_RESTART_TRESHOLD}"
        ifconfig wlan0 up
        log_msg "Waiting 10 seconds to re-establish connection."
        sleep 10
    fi
}
