# Sonar

Sonar - A WiFi Keepalive daemon

# Developer Documentation

To use Sonar with [CustoPiZer](https://github.com/OctoPrint/CustoPiZer), \
simply copy file 'scripts/10_sonar.sh' to your scripts folder.

After that copy:

    #### Sonar Setup [10_sonar.sh]
    # There is not much to setup, because it reuses sonars install script
    # Install of Sonar bool (1:yes / 0:no)
    EDITBASE_INSTALL_SONAR=1
    # Add Sonar to moonraker.conf (update manager) bool (1:yes / 0:no)
    EDITBASE_ADD_SONAR_MOONRAKER=1
    EDITBASE_SONAR_REPO_SHIP="https://github.com/mainsail-crew/sonar.git"
    EDITBASE_SONAR_REPO_BRANCH="main"

to your config.local and setup to your needs.
