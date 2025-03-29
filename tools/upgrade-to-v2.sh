#!/usr/bin/env bash
# shellcheck disable=SC2317

## These two functions are reused from custompios common.sh
## Credits to guysoft!
## https://github.com/guysoft/CustomPiOS

# Message Vars
SR_OK="\e[32mOK\e[0m"
SR_SK="\e[33mSKIPPED\e[0m"

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

main() {
    install_cleanup_trap

    echo -e "Sonar - A WiFi Keepalive daemon\n"

    if [ ! -L "/usr/local/bin/sonar" ]; then
        echo -e "Sonar is not installed."
        exit 1
    fi

    local sonar_path
    sonar_path=$(dirname "$(readlink /usr/local/bin/sonar)")

    if [ ! -d "${sonar_path}" ]; then
        echo -e "Sonar Directory not found."
        exit 1
    fi

    local home_path
    home_path=$(dirname "${sonar_path}")

    echo -e "Finding all directories ..."
    echo -e "Sonar is installed in ${sonar_path}"

    local config_file config_path printer_data_path
    config_file=$(find "${home_path}" -name "sonar.conf" -not -path "${sonar_path}/resources/*" -type f | head -n1)
    config_path=$(dirname "${config_file}")
    printer_data_path=$(dirname "${config_path}")
    env_path="${printer_data_path}/systemd"

    echo -e "Printer Data Path is ${printer_data_path}"

    echo -en "Update sonar.conf ...\r"
    sed -i "s|restart_treshold|restart_threshold|g" "${config_file}"
    echo -e "Update sonar.conf ... [${SR_OK}]"

    echo -en "Copying new files ...\r"
    local resources_env="${sonar_path}/resources/sonar.env"
    local resources_service="${sonar_path}/resources/sonar.service"

    cp -f "${resources_env}" "${env_path}/sonar.env"
    cp -f "${resources_service}" "/etc/systemd/system/sonar.service"
    echo -e "Copying new files ... [${SR_OK}]"

    echo -en "Updating user in sonar.env ...\r"
    sed -i "s|%sonarpath%|${sonar_path}|g" "${env_path}/sonar.env"
    sed -i "s|%configpath%|${config_path}|g" "${env_path}/sonar.env"
    echo -e "Updating user in sonar.env ... [${SR_OK}]"

    echo -en "Updating user in sonar.service ...\r"
    sed -i "s|%envpath%|${env_path}|g" "/etc/systemd/system/sonar.service"
    echo -e "Updating user in sonar.service ... [${SR_OK}]"

    echo -en "Reloading systemd ...\r"
    systemctl daemon-reload
    echo -e "Reloading systemd ... [${SR_OK}]"

    echo -en "Removing old sonar binary ...\r"
    rm -f "/usr/local/bin/sonar"
    echo -e "Removing old sonar binary ... [${SR_OK}]"

    echo -en "Restarting sonar.service ...\r"
    systemctl restart sonar.service
    echo -e "Restarting sonar.service ... [${SR_OK}]"

    echo -e "Done!"
}

main
exit 0
