#### Sonar - A WiFi Keepalive daemon
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2022
#### https://github.com/mainsail-crew/sonar
####
#### This File is distributed under GPLv3
####

.PHONY: help install unsinstall update

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
	@echo "   update       Updates sonar (if needed)"
	@echo ""

install:
	@bash -c 'tools/install.sh'

unattended:
	@bash -c 'tools/install.sh -z'

uninstall:
	@bash -c 'tools/uninstall.sh'

update:
	@bash -c 'tools/update.sh'
