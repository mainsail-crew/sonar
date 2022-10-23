# Sonar

A small Keepalive daemon for MainsailOS (or any other Raspberry Pi OS based Image).

---

## Install

    git clone https://github.com/mainsail-crew/sonar.git
    cd ~/sonar
    make install

### Install Option

To use a customized path for the persistant Log file, \
you could create a file called config.local in 'tools' directory

Put a Variable in that file

    SONAR_PERSISTANT_LOG_PATH="/path/to/my/persistant/log/destination"

This will be the path where you find the logfile.

By default, it will be

    /home/<username>/printer_data/logs

## Uninstall

    cd ~/sonar
    make uninstall

## Updating via moonraker's update manager

Simply add

    [update_manager sonar]
    type: git_repo
    path: ~/sonar
    origin: https://github.com/mainsail-crew/sonar.git
    primary_branch: main
    managed_services: sonar

to your moonraker.conf

## Configuration

You are able to configure it's behavior due a file in "printer_data".\
But you don't have to. Defaults are hardcoded and sonar will run without any configuration.\
Easiest way is to copy the file from "sample_config" in this repo.

    cd ~/sonar
    cp sample_config/sonar.conf ../printer_data/config/

### Options

    enable: true

If set to "false" service will exit on startup, use this option to disable Sonar service. \
It will restart on reboot but exiting as long you don't change it to "true".

    debug_log: false

If set to "true" service will log every attempt to reach his target. \
**_NOTE: That will highly increase log size, this is intended for debugging purposes only._**

    persistant_log: false

This option allows you to store a persistant log file "/var/log/sonar.log" if set to "true" \
Otherwise it will be only readable by

    journalctl -u sonar

and it's _not_ persistant!

    target: auto

Your target defines which of your network devices should be target of used 'ping' command \
You can use either IP Address or a URL. 'auto' will ping your default gateway (router).\
**_INFO: Avoid using prefixes like https:// or http://_**

    count: 3

How often should be pinged?

    interval: 60

Sets interval in seconds, how long it should wait for next connection check.

    restart_treshold: 10

The last option is a delay, in seconds, between shutdown WiFi Interface and bring it up again.

---

That's it. It is'nt the best method to keep your Wifi up and running but it is the easiest solution without changing firmware files or similar.

I hope you will find sonar useful and it blows away your connection losts :)

### Contributing

See [How to contribute?](https://github.com/mainsail-crew/sonar/blob/main/.github/CONTRIBUTING.md)
