#### Sonar - A WiFi Keepalive daemon
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2022
#### https://github.com/mainsail-crew/sonar
####
#### This File is distributed under GPLv3
####

# Default values for the install script

INSTALL_SERVICE ?= 1
UNATTENDED ?= 0

.PHONY: config help install uninstall

all: help

help:
	@echo "This is intended to install sonar."
	@echo ""
	@echo "Some Parts need 'sudo' privileges."
	@echo "You'll be asked for password, if needed."
	@echo ""
	@echo " Usage: make [action]"
	@echo ""
	@echo "  Available actions:"
	@echo ""
	@echo "   install      Installs sonar"
	@echo "   uninstall    Uninstalls sonar"
	@echo "   config       configure installer"
	@echo ""
	@echo "  Available options for install:"
	@echo "   -d          Set custom data directory (for example -d /home/user/printer_data)"
	@echo "   -s          Skip installation of service file"
	@echo "   -x          Unattended installation"
	@echo ""
	@echo "  Available options for install:"
	@echo "   DATA_PATH=<path>    Set custom data directory (for example DATA_PATH=/home/user/printer_data)"
	@echo "   INSTALL_SERVICE=0   Skip installation of service file"
	@echo "   UNATTENDED=1        Unattended installation"
	@echo ""

install:
	@bash tools/install.sh \
		DATA_PATH=$(DATA_PATH) \
		INSTALL_SERVICE=$(INSTALL_SERVICE) \
		UNATTENDED=$(UNATTENDED)

config:
	@bash -c 'tools/configure.sh'

uninstall:
	@bash -c 'tools/uninstall.sh'

update:
	git fetch && git pull
