#!/bin/bash

#### message library

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

## Message Helpers
function wrong_args_msg {
    echo -e "Sonar: Invalid argument!\n"
    help_msg
}

function help_msg {
    echo -e "sonar - WiFi Keepalive deamon\nUsage:"
    echo -e "\t sonar [Options]"
    echo -e "\n\t\t-h Prints this help."
    echo -e "\n\t\t-v Prints Version of sonar."
    echo -e "\n\t\t-c </path/to/configfile>\n\t\t\tPath to your sonar.conf\n"
}
