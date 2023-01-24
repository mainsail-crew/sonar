#!/usr/bin/env bash

#### Core library

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

# Service disabled by default
function run_service {
    local service
    service="$(get_param sonar enable)"
    if [[ "${service}" == "false" ]]; then
        log_msg "Sonar.service disabled by configuration ..."
        if [[ "$(systemctl is-active sonar.service 2> /dev/null)" != "inactive" ]]; then
            log_msg "INFO: Service will be halted until next reboot ..."
            log_msg "INFO: GoodBye ..."
            systemctl stop sonar.service
        else
            log_msg "WARN: Sonar Service already inactive ..."
            log_msg "INFO: Exiting! GoodBye ..."
            exit 0
        fi
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

# Initial Check
function initial_check {
    log_msg "INFO: Checking Dependencys"
    check_dep "crudini"
    check_eth_con
    run_service
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

function check_connection {
    ping -q -c"${1}" "${2}" | tail -n1 | sed '/pipe.*/d;s/rtt/Triptime:/'
}

function setup_env {
    local target
    target="$(get_param sonar target)"
    # Use default values if parameter is missing
    if [[ "${target}" == "auto" ]]; then
        SONAR_TARGET="$(get_def_gw)"
    else
        SONAR_TARGET="${target}"
    fi
    SONAR_PING_COUNT="$(get_param sonar count || echo "3")"
    SONAR_CHECK_INTERVAL="$(get_param sonar interval || echo "60")"
    SONAR_RESTART_TRESHOLD="$(get_param sonar restart_treshold || echo "10")"
    SONAR_DEBUG_LOG="$(get_param sonar debug_log || echo "false")"
    declare -r SONAR_TARGET
    declare -r SONAR_PING_COUNT
    declare -r SONAR_CHECK_INTERVAL
    declare -r SONAR_RESTART_TRESHOLD
    declare -r SONAR_DEBUG_LOG

    # Set vars only once!
    SONAR_SETUP_COMPLETE=1
    declare -r SONAR_SETUP_COMPLETE
}

function keepalive {
    local triptime
    triptime="$(check_connection "${SONAR_PING_COUNT}" "${SONAR_TARGET}")"
    if [[ "${SONAR_SETUP_COMPLETE}" != "1" ]]; then
        setup_env
    fi
    if [[ -n "${triptime}" ]]; then
        if [[ "${SONAR_DEBUG_LOG}" == "true" ]]; then
            log_msg "Reached ${SONAR_TARGET}, ${triptime}"
        fi
    else
        log_msg "Connection lost, ${SONAR_TARGET} not reachable!"
        log_msg "Restarting network in ${SONAR_RESTART_TRESHOLD} seconds."
        sleep "${SONAR_RESTART_TRESHOLD}"
        log_msg "Reassociate WiFi connection ..."
        wpa_cli -i wlan0 reassociate &> /dev/null
        log_msg "Restarting dhcpcd service ..."
        systemctl restart dhcpcd
        log_msg "Waiting 10 seconds to re-establish connection."
        sleep 10
    fi
    sleep "${SONAR_CHECK_INTERVAL}"
}
