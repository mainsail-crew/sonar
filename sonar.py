#!/usr/bin/env python3
"""
Sonar - A WiFi Keepalive Daemon in Python

This program pings a target (e.g., the router) at regular intervals to detect a
WiFi outage. If an outage is detected, it attempts to restore the WiFi
connection by using various methods, such as wpa_cli reassociation, restarting
the dhcpcd service, or restarting the NetworkManager service.

Configuration:
  The program loads optional parameters from a configuration file (default:
  sonar.conf) in INI format. For example:

    [sonar]
    enable = true
    debug_log = false
    persistant_log = false
    target = auto
    count = 3
    interval = 60
    restart_threshold = 10

  If "auto" is set for the target, the default gateway (router IP) is determined
  automatically.

Note: If persistant_log is enabled, logs will be written to /var/log/sonar.log.
"""

import subprocess
import time
import configparser
import os
import re
import sys
import shutil
import logging


class SonarDaemon:
    """Sonar - A WiFi Keepalive Daemon"""

    def __init__(self):
        # Set up logging
        self.logger = logging.getLogger("sonar")
        self.logger.setLevel(logging.INFO)
        formatter = logging.Formatter('[%(asctime)s] %(message)s',
                                      datefmt='%m/%d/%Y %H:%M:%S')

        # Clear existing handlers
        self.logger.handlers = []

        # Set up console logging
        ch = logging.StreamHandler(sys.stdout)
        ch.setFormatter(formatter)
        self.logger.addHandler(ch)

        # Load configuration
        self.load_config()

    def load_config(self):
        config = configparser.ConfigParser(inline_comment_prefixes='#')

        # Check new moonraker structure for config file
        script_path = os.path.dirname(os.path.abspath(__file__))
        home_path = os.path.dirname(script_path)

        # define paths for new and old config files
        new_path = os.path.join(home_path, "printer_data/config/sonar.conf")
        old_path = os.path.join(home_path, "klipper_config/sonar.conf")
        fallback_path = os.path.join(script_path, "resources/sonar.conf")

        if os.path.exists(new_path):
            config.read(new_path)
        elif os.path.exists(old_path):
            config.read(old_path)
        elif os.path.exists(fallback_path):
            config.read(fallback_path)
        else:
            self.logger.warning("No configuration file found. Using default values.")
            config.add_section("sonar")

        if 'sonar' in config:
            config = config['sonar']

        self.config = {
            'enable': config.getboolean('enable', fallback=False),
            'debug_log': config.getboolean('debug_log', fallback=True),
            'persistant_log': config.getboolean('persistant_log',
                                                fallback=False),
            'target': config.get('target', fallback="auto"),
            'count': config.getint('count', fallback=3),
            'interval': config.getint('interval', fallback=60),
            'restart_threshold': config.getint('restart_threshold', fallback=10)
        }

        if self.config['debug_log']:
            self.logger.info(f"Configuration loaded:")
            self.logger.info(f"  enable: {self.config['enable']}")
            self.logger.info(f"  debug_log: {self.config['debug_log']}")
            self.logger.info(f"  persistant_log: {self.config['persistant_log']}")
            self.logger.info(f"  target: {self.config['target']}")
            self.logger.info(f"  count: {self.config['count']}")
            self.logger.info(f"  interval: {self.config['interval']}")
            self.logger.info(f"  restart_threshold: {self.config['restart_threshold']}")

    def _is_service_active(self, service_name):
        try:
            result = subprocess.run(["systemctl", "is-active", service_name],
                                    capture_output=True, text=True)
            return result.stdout.strip() == "active"
        except Exception:
            return False

    def get_default_gateway(self):
        # Regex pattern to extract gateway, device name, source IP, and metric
        pattern = r'default via (\S+).*? dev (\S+).*?src (\S+).*?metric (\d+)'

        try:
            route_output = subprocess.run(["ip", "route", "show", "default"],
                                          capture_output=True, text=True)

            if route_output.returncode != 0:
                self.logger.warning(f"Error retrieving default route: {route_output.stderr}")
                return None

            if route_output.stdout == "":
                self.logger.warning("No default route found.")
                return None

            matches = re.findall(pattern, route_output.stdout)

            if not matches:
                self.logger.warning("No matching routes found.")
                return None

            # Sort matches by metric (ascending order)
            matches.sort(key=lambda x: int(x[3]))

            return {
                'gateway': matches[0][0],  # Gateway IP
                'interface': matches[0][1],  # Device name (e.g., wlan0)
                'src': matches[0][2],  # Source IP
                'metric': int(matches[0][3])  # Metric value
            }
        except Exception as e:
            self.logger.error(f"Error retrieving default gateway: {e}")
            return None

    def restart_wifi(self, interface="wlan0"):
        exists_wpa_cli = shutil.which("wpa_cli")
        is_dhcpcd_active = self._is_service_active("dhcpcd")
        is_network_manager_active = self._is_service_active("NetworkManager")

        self.logger.info("Attempting to restart WiFi connection...")
        if exists_wpa_cli and is_dhcpcd_active:
            try:
                subprocess.run(["wpa_cli", "-i", interface, "reassociate"],
                               check=True)
                self.logger.info("WiFi reconnected using wpa_cli reassociate.")
                subprocess.run(["systemctl", "restart", "dhcpcd"],
                               check=True)
                self.logger.info("dhcpcd service restarted.")
                return
            except subprocess.CalledProcessError:
                self.logger.warning("wpa_cli reassociate failed or failed to"
                                    " restart dhcpcd.")
        elif is_network_manager_active:
            try:
                subprocess.run(["systemctl", "restart",
                                "NetworkManager.service"], check=True)
                self.logger.info("NetworkManager service restarted.")
                return
            except subprocess.CalledProcessError:
                self.logger.warning("Restarting NetworkManager failed.")
        else:
            self.logger.error("No active service found to restart WiFi"
                              " connection.")

    def ping_target(self, target, count):
        try:
            result = subprocess.run(["ping", "-c", str(count), target],
                                    capture_output=True, text=True)
            if result.returncode != 0:
                return False

            # Stop here and return if debug_log is not enabled
            if not self.config['debug_log']:
                return True

            lines = result.stdout.splitlines()
            summary = lines[-1]
            self.logger.debug(f"Ping to {target} successful: {summary}")

            return True
        except Exception as e:
            self.logger.error(f"Error executing ping: {e}")
            return False

    def run(self):
        self.logger.info("Starting Sonar – WiFi Keepalive Daemon.")

        # Set up persistant logging if enabled
        if self.config['persistant_log']:
            log_file = "/var/log/sonar.log"
            try:
                formatter = logging.Formatter('[%(asctime)s] %(message)s',
                                              datefmt='%m/%d/%Y %H:%M:%S')
                fh = logging.FileHandler(log_file)
                fh.setFormatter(formatter)
                self.logger.addHandler(fh)
            except PermissionError:
                self.logger.warning(f"No permission to write to {log_file}. "
                                    f"Using stdout instead.")

        # Set debug level if needed
        if self.config['debug_log']:
            self.logger.setLevel(logging.DEBUG)
            self.logger.debug("Debug logging enabled.")

        if not self.config['enable']:
            self.logger.info("Sonar is disabled in the configuration. Exiting.")
            sys.exit(0)

        while True:
            gateway = self.get_default_gateway()

            if not gateway:
                self.logger.warning("No default gateway found. Retrying...")
                time.sleep(self.config['interval'])
                continue

            if not gateway['interface'].startswith(('wl', 'wlan', 'wlp')):
                self.logger.debug(f"No WiFi interface active for the default gateway."
                                  f" {gateway['interface']} is not a WiFi interface."
                                  f" Retrying...")
                time.sleep(self.config['interval'])
                continue

            target = self.config['target']
            if target == "auto":
                target = gateway['gateway']

            if not self.ping_target(target, self.config['count']):
                restart_threshold = self.config['restart_threshold']
                self.logger.info(f"Connection lost – {target} is unreachable!")
                self.logger.info(f"Waiting {restart_threshold} seconds before"
                                 f" attempting a restart.")
                time.sleep(restart_threshold)

                retry_count = 0
                used_retries = 0
                # Repeat until a single ping is successful
                while not self.ping_target(target, 1):
                    used_retries += 1
                    retry_count += 1
                    self.restart_wifi(gateway['interface'])
                    self.logger.info("Waiting 10 seconds to re-establish the connection...")
                    time.sleep(10)
                    if retry_count == 3:
                        self.logger.warning(
                            f"Reconnection attempt failed after {retry_count} tries."
                            f" Pausing for {self.config['interval']} seconds.")
                        time.sleep(self.config['interval'])
                        retry_count = 0

                self.logger.info(f"Reconnected after {used_retries} attempts.")

            time.sleep(self.config['interval'])


if __name__ == "__main__":
    try:
        daemon = SonarDaemon()
        daemon.run()
    except KeyboardInterrupt:
        print("\nSonar daemon interrupted by user. Exiting.")
        sys.exit(0)
