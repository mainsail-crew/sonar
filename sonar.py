#!/usr/bin/env python3
"""
Sonar - A WiFi Keepalive Daemon in Python

This program pings a target (e.g., the router) at regular intervals to detect a WiFi outage.
If an outage is detected, it attempts to restore the WiFi connection by using various methods,
such as wpa_cli reassociation, restarting the dhcpcd service, or restarting the NetworkManager service.

Configuration:
  The program loads optional parameters from a configuration file (default: sonar.conf)
  in INI format. For example:

    [sonar]
    enable = true
    debug_log = false
    persistant_log = false
    target = auto
    count = 3
    interval = 60
    restart_threshold = 10

  If "auto" is set for the target, the default gateway (router IP) is determined automatically.

Note: If persistant_log is enabled, logs will be written to /var/log/sonar.log.
"""

import subprocess
import time
import configparser
import os
import sys
import shutil
import logging


def get_default_gateway():
    """
    Determines the default gateway (router IP) using the "ip route" command.
    Expected output: "default via 192.168.1.1 dev wlan0 ..."
    """
    try:
        result = subprocess.run(["ip", "route", "show", "default"],
                                capture_output=True, text=True)
        if result.returncode == 0:
            parts = result.stdout.split()
            if "via" in parts:
                idx = parts.index("via")
                if idx + 1 < len(parts):
                    return parts[idx + 1]
    except Exception as e:
        log_msg(f"Error retrieving gateway: {e}")
    return None


def load_config(config_file="sonar.conf"):
    """
    Loads the configuration from the file config_file (in INI format).
    If the file does not exist, default values are used.
    """
    config = configparser.ConfigParser()
    defaults = {
        'enable': 'false',
        'debug_log': 'false',
        'persistant_log': 'false',
        'target': 'auto',
        'count': '3',
        'interval': '60',
        'restart_threshold': '10'
    }
    if os.path.exists(config_file):
        config.read(config_file)
        if 'sonar' in config:
            sonar_conf = config['sonar']
        else:
            sonar_conf = defaults
    else:
        sonar_conf = defaults

    enable = sonar_conf.getboolean('enable', fallback=False)
    debug_log = sonar_conf.getboolean('debug_log', fallback=False)
    persistant_log = sonar_conf.getboolean('persistant_log', fallback=False)
    target = sonar_conf.get('target', fallback='auto')
    if target == 'auto':
        gw = get_default_gateway()
        if gw:
            target = gw
        else:
            print("Default gateway could not be determined. Exiting.")
            sys.exit(1)
    count = sonar_conf.getint('count', fallback=3)
    interval = sonar_conf.getint('interval', fallback=60)
    restart_threshold = sonar_conf.getint('restart_threshold', fallback=10)

    return {
        'enable': enable,
        'debug_log': debug_log,
        'persistant_log': persistant_log,
        'target': target,
        'count': count,
        'interval': interval,
        'restart_threshold': restart_threshold
    }


def setup_logging(persistant_log):
    """
    Sets up logging.
    If persistant_log is enabled, logs will be written to /var/log/sonar.log;
    otherwise, output is directed to stdout.
    """
    logger = logging.getLogger("sonar")
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter('[%(asctime)s] %(message)s', datefmt='%m/%d/%Y %H:%M:%S')

    if persistant_log:
        log_file = "/var/log/sonar.log"
        try:
            fh = logging.FileHandler(log_file)
        except PermissionError:
            print(f"No permission to write to {log_file}. Using stdout instead.")
            fh = None
        if fh:
            fh.setFormatter(formatter)
            logger.addHandler(fh)
    ch = logging.StreamHandler(sys.stdout)
    ch.setFormatter(formatter)
    logger.addHandler(ch)
    return logger


def is_service_active(service_name):
    """
    Checks whether a systemd service is active.
    """
    try:
        result = subprocess.run(["systemctl", "is-active", service_name],
                                capture_output=True, text=True)
        return result.stdout.strip() == "active"
    except Exception:
        return False


def restart_wifi(logger):
    """
    Attempts to restore the WiFi connection.
    The following methods are tried:
      - Using wpa_cli: "wpa_cli -i wlan0 reassociate"
      - Restarting the dhcpcd service (if active)
      - Restarting the NetworkManager service (if active)
    """
    logger.info("Attempting to restart WiFi connection...")
    if shutil.which("wpa_cli"):
        try:
            subprocess.run(["wpa_cli", "-i", "wlan0", "reassociate"], check=True)
            logger.info("WiFi reconnected using wpa_cli reassociate.")
            return
        except subprocess.CalledProcessError:
            logger.warning("wpa_cli reassociate failed.")
    if is_service_active("dhcpcd"):
        try:
            subprocess.run(["systemctl", "restart", "dhcpcd"], check=True)
            logger.info("dhcpcd service restarted.")
            return
        except subprocess.CalledProcessError:
            logger.warning("Restarting dhcpcd failed.")
    if is_service_active("NetworkManager"):
        try:
            subprocess.run(["systemctl", "restart", "NetworkManager.service"], check=True)
            logger.info("NetworkManager service restarted.")
            return
        except subprocess.CalledProcessError:
            logger.warning("Restarting NetworkManager failed.")
    logger.error("Failed to restart WiFi connection with available methods.")


def ping_target(target, count, logger):
    """
    Pings the target with the specified number of pings.
    Returns True if at least one ping is successful, otherwise False.
    """
    try:
        result = subprocess.run(["ping", "-c", str(count), target],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                text=True)
        if result.returncode == 0:
            if logger.isEnabledFor(logging.DEBUG):
                lines = result.stdout.splitlines()
                if lines:
                    summary = lines[-1]
                    logger.debug(f"Ping successful: {summary}")
            return True
        else:
            logger.info(f"Ping failed. Output: {result.stdout.strip()} {result.stderr.strip()}")
            return False
    except Exception as e:
        logger.error(f"Error executing ping: {e}")
        return False


def log_msg(message):
    """
    Fallback output if the logger is not yet initialized.
    """
    print(f"[{time.strftime('%m/%d/%Y %H:%M:%S')}] {message}")


def main():
    # Load configuration from sonar.conf
    config = load_config("sonar.conf")
    # Set up logging
    logger = setup_logging(config['persistant_log'])
    logger.info("Starting Sonar – WiFi Keepalive Daemon.")

    if not config['enable']:
        logger.info("Sonar is disabled in the configuration. Exiting.")
        sys.exit(0)

    target = config['target']
    count = config['count']
    interval = config['interval']
    restart_threshold = config['restart_threshold']
    debug_log = config['debug_log']

    if debug_log:
        logger.setLevel(logging.DEBUG)
        logger.debug("Debug logging enabled.")

    while True:
        if ping_target(target, count, logger):
            if debug_log:
                logger.debug(f"{target} is reachable.")
        else:
            logger.info(f"Connection lost – {target} is unreachable!")
            logger.info(f"Waiting {restart_threshold} seconds before attempting a restart.")
            time.sleep(restart_threshold)
            retry_count = 0
            used_retries = 0
            # Repeat until a single ping is successful
            while not ping_target(target, 1, logger):
                used_retries += 1
                retry_count += 1
                restart_wifi(logger)
                logger.info("Waiting 10 seconds to re-establish the connection...")
                time.sleep(10)
                if retry_count == 3:
                    logger.warning(f"Reconnection attempt failed after {retry_count} tries. Pausing for {interval} seconds.")
                    time.sleep(interval)
                    retry_count = 0
            logger.info(f"Reconnected after {used_retries} attempts.")
        time.sleep(interval)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nSonar daemon interrupted by user. Exiting.")
        sys.exit(0)
