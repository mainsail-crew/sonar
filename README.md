# Sonar

A small Keepalive daemon for MainsailOS (or any other Raspberry Pi OS based Image).

---

## Install

    git clone https://github.com/mainsail-crew/sonar
    cd ~/sonar
    make install

## Uninstall

    cd ~/sonar
    make uninstall

## Update (if needed)

    cd ~/sonar
    git pull
    make update

## Configuration

You are able to configure it's behavior due a file in "klipper_config".\
Easiest way is to copy the file from "sample_config" in this repo.

    cd ~/sonar
    cp sample_config/sonar.conf ../klipper_config/

### Options

    persistant_log: false

This option allows you to store a persistant log file "/var/log/sonar.log" if set to "true" \
Otherwise it will be only readable by

    journalctl -u sonar

and it's _not_ persistant!

    target: auto

Your target defines which of your network devices should be target of used 'ping' command \
You can use either IP Address or a URL. 'auto' will ping your default gateway (router).
**_INFO: Avoid using prefixes like https:// or http://_**

    count: 3

How often should be pinged?

    interval: 5

Sets interval in seconds, how long it should wait for next connection check.

    restart_treshold: 10

The last option is a delay, in seconds, between shutdown WiFi Interface and bring it up again.

### Updating via moonraker's update manager

Simply add

    [update_manager sonar]
    type: git_repo
    path: ~/sonar
    origin: https://github.com/KwadFan/sonar.git
    primary_branch: main
    is_system_service: True

to your moonraker.conf

That's it. It is'nt the best method to keep your Wifi up and running but it is the easiest solution without changing firmware files or similar.

I hope you will find sonar useful and it blows away your connection losts :)
