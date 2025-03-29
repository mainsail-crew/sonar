# Sonar

A small Keepalive daemon for MainsailOS (or any other Raspberry Pi OS based
Image).

---

## Install

    git clone https://github.com/mainsail-crew/sonar.git
    cd ~/sonar
    make config
    sudo make install

## Uninstall

    cd ~/sonar
    make uninstall

## Updating via moonraker update manager

Simply add

    [update_manager sonar]
    type: git_repo
    path: ~/sonar
    origin: https://github.com/mainsail-crew/sonar.git
    primary_branch: main
    managed_services: sonar
    install_script: tools/install.sh

to your moonraker.conf

## Configuration

You can configure its behavior using a file in
"~/printer_data/config/sonar.conf". But you don't have to. Defaults are
hardcoded and Sonar will run without any configuration.

_**Hint: The Sonar's configuration file syntax is based on [TOML](https://toml.io/en/)
other than in TOML colons are also valid (and prettier). Therefore, a leading
section descriptor is crucial!**_

    [sonar]

### Options

    enable: true

If set to "false" service will exit on startup, use this option to disable Sonar
service. It will restart on reboot but exiting as long you don't change it to
"true".

    debug_log: false

If set to "true" service will log every attempt to reach its target.
**_NOTE: That will highly increase log size, this is intended for debugging
purposes only._**

    persistent_log: false

This option allows you to store a persistent log file "/var/log/sonar.log".
Otherwise, it will be only readable by `journalctl -u sonar` and it's _not_
persistent!

    target: auto

Your target defines which of your network devices should be the target of used
`ping` command. You can use either IP Address or a URL. `auto` will ping your
default gateway (router).
**_INFO: Avoid using prefixes like https:// or http://_**

    count: 3

Number of ping attempts.

    interval: 60

Sets interval in seconds, how long it should wait for next connection check.

    restart_threshold: 10

Delay in seconds before attempting to restart the WiFi connection after a
connection loss.

---

That's it. It isn't the best method to keep your WiFi up and running, but it is
the easiest solution without changing firmware files or similar.

I hope you will find sonar useful, and it blows away your connection lost :)

### Contributing

See [How to contribute?](https://github.com/mainsail-crew/sonar/blob/main/.github/CONTRIBUTING.md)
