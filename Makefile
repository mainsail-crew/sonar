#### Sonar - A WiFi Keepalive daemon
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2022
#### https://github.com/mainsail-crew/sonar
####
#### This File is distributed under GPLv3
####

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

install:
	@bash tools/install.sh $(filter-out $@,$(MAKECMDGOALS))

%:
	@:

config:
	@bash -c 'tools/configure.sh'

uninstall:
	@bash -c 'tools/uninstall.sh'

update:
	git fetch && git pull
