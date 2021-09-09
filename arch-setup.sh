#!/usr/bin/bash
#
# arch-setup.sh: Setup script for Arch Linux.
#
# Copyright (c) 2021 James Anderson-Pole <james@pole.net.nz>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.
#

#
# Exit early if not running as root.
#

if [ "${UID}" -ne 0 ]; then
    echo 'Run this script as root.'
    exit 1
fi

#
# Set certain variables depending on environment.
#

if [[ ${HOSTNAME} == *-laptop ]]; then
    _laptop='true'
    _nmconnections='Anderson2 James-Phone'
else
    _laptop=''
fi

if [[ ${HOSTNAME} == *.pole.net.nz ]]; then
    _certbot_domains='
        pole.net.nz
        james.pole.net.nz
        neptune.pole.net.nz
        www.pole.net.nz'
    _nmconnections='Prodigi'
    _server='true'
else
    _server=''
fi

#
# Internal variables.
#

_sections=''
_self_name='arch-setup'

#
# Fuctions for printing coloured output.
#

# Generic function for printing coloured output.
# - Argument 1 ($1): Colour number
# - Argument 2 ($2): Text to be printed
print_colour () {
    if [ $# -ne 2 ]; then
        echo 'Function print_colour() expects 2 arguments.'
        exit 1
    fi
    echo -en "\033[0;${1}m"
    echo -n "[${SECONDS}] ${_self_name}:"
    echo -en "\033[0m"
    echo " $2"
}

# Prints error text.
print_error () {
    if [ $# -ne 1 ]; then
        echo 'Function print_error() expects 1 argument.'
        exit 1
    fi
    print_colour 31 "$1"
}

# Prints informational text.
print_info () {
    if [ $# -ne 1 ]; then
        echo 'Function print_info() expects 1 argument.'
        exit 1
    fi
    print_colour 33 "$1"
}

# Prints section-related text.
print_section () {
    if [ $# -ne 1 ]; then
        echo 'Function print_section() expects 1 argument.'
        exit 1
    fi
    print_colour 35 "$1"
}

# Prints success text.
print_success () {
    if [ $# -ne 1 ]; then
        echo 'Function print_success() expects 1 argument.'
        exit 1
    fi
    print_colour 32 "$1"
}

#
# Functions for creating and checking sections.
#

# Checks for section(s), and exits with an error if any have not been registered.
section_check () {
    if [ $# -eq 0 ]; then
        print_error 'Function section_check() expects at least 1 argument.'
        exit 1
    fi
    for section_to_check in "$@"; do
        if ! section_exists "${section_to_check}"; then
            print_error "Section <${section_to_check}> has not yet been registered."
            exit 1
        fi
    done
}

# Returns whether a section eixsts or not.
section_exists () {
    if [ $# -ne 1 ]; then
        print_error 'Function section_exists() expects 1 argument.'
        exit 1
    fi
    for section in ${_sections}; do
        if [ "$1" = "${section}" ]; then
            return 0
        fi
    done
    return 1
}

# Register a section, so it can be checked by other sections later.
section_register () {
    if [ $# -ne 1 ]; then
        print_error 'Function section_register() expects 1 argument.'
        exit 1
    fi
    if section_exists "$1"; then
        print_error "Section <$1> already exists."
        exit 1
    fi
    _sections+=" $1"
    print_section "Section $1"
}

#
# Fuctions for common tasks.
#

# Install a file, if it is not installed already.
# Either two -OR- five arguments can be provided.
# - Argument 1 ($1): Source file.
# - Argument 2 ($2): Full path of target file.
# Either all the following arguments must be provided -OR- the default will apply.
# - Argument 3 ($3): Owner of file.           } Default: root
# - Argument 4 ($4): Group of file.           } Default: root
# - Argument 5 ($5): Permission mode of file. } Default: 0644
file_install () {
    if [ $# -ne 2 ] && [ $# -ne 5 ]; then
        print_error 'Function file_install() expects either 2 or 5 arguments.'
        exit 1
    fi
    file_owner='root'
    file_group='root'
    file_mode='0644'
    if [ $# -eq 5 ]; then
        file_owner="$3"
        file_group="$4"
        file_mode="$5"
    fi
    install --backup=numbered --compare \
        --owner="${file_owner}" \
        --group="${file_group}" \
        --mode="${file_mode}" \
        "$1" "$2" || exit
}

# Install a package, if it is not installed alraedy.
package_install () {
    if [ $# -ne 1 ]; then
        print_error 'Function package_install() expects 1 argument.'
        exit 1
    fi
    if ! pacman --query "$1" &> /dev/null; then
        pacman --sync --needed --noconfirm --quiet "$1" || exit
    fi
}

#
# Start of sections.
#

section_register 'Pacman'
file_install pacman/pacman.conf /etc/pacman.conf
file_install pacman-mirrorlist/mirrorlist /etc/pacman.d/mirrorlist
pacman --sync --refresh --sysupgrade --quiet --noconfirm || exit
pacman --files --noconfirm --refresh --quiet || exit

#
# Section: Manual_Pages
#

section_register 'Manual_Pages'
section_check 'Pacman'
package_install 'man-db'
package_install 'man-pages'
systemctl enable man-db.timer || exit
systemctl restart man-db.timer || exit

#
# Section: CRDA
#

if [ "${_laptop}" = 'true' ]; then
    section_register 'CRDA'
    section_check 'Manual_Pages'
    section_check 'Pacman'
    package_install 'crda'
    file_install wireless-regdom/wireless-regdom /etc/conf.d/wireless-regdom
fi

#
# Section: systemd-resolved
#

section_register 'systemd-resolved'
section_check 'Manual_Pages'
file_install systemd/resolved.conf /etc/systemd/resolved.conf
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf || exit
systemctl enable systemd-resolved.service || exit
systemctl restart systemd-resolved.service || exit

#
# Section: NetworkManager
#

section_register 'NetworkManager'

# Only check for CRDA on laptops, because CRDA relates to wireless networking.
if [ "${_laptop}" = 'true' ]; then
    section_check 'CRDA'
fi

section_check 'Manual_Pages'
section_check 'Pacman'
section_check 'systemd-resolved'
package_install 'networkmanager'

# Install NetworkManager connection files.
for nmconnection in ${_nmconnections}; do
    file_install "networkmanager/${nmconnection}.nmconnection" \
        "/etc/NetworkManager/system-connections/${nmconnection}.nmconnection" \
        root root 0600
done

# Ensure systemd-networkd is stopped and disabled. We need to do this to ensure
# it does not conflict with NetworkManager.
systemctl stop systemd-networkd.service || exit
systemctl disable systemd-networkd.service || exit

# Ensure NetworkManager is enabled and restarted. Note a restart (not a reload)
# is required. Reloading NetworkManager does not activate any new or updated
# NetworkManager connection files.
systemctl enable NetworkManager.service || exit
systemctl restart NetworkManager.service || exit

# Before we proceed with the rest of this script, check that NetworkManager has
# obtained an internet connection.
nm-online || exit

#
# Section: systemd-timesyncd
#

section_register 'systemd-timesyncd'
section_check 'Manual_Pages'
section_check 'NetworkManager'
section_check 'Pacman'
section_check 'systemd-resolved'
file_install systemd/timesyncd.conf /etc/systemd/timesyncd.conf
systemctl enable systemd-timesyncd.service || exit
systemctl restart systemd-timesyncd.service || exit

#
# Section: Timezone
#

section_register 'Timezone'
section_check 'Pacman'
ln -sf /usr/share/zoneinfo/Pacific/Auckland /etc/localtime

#
# Section: OpenSSH
# Documentation: https://wiki.archlinux.org/title/OpenSSH
#

section_register 'OpenSSH'

# Check that Manual_Pages is done, for manual pages.
section_check 'Manual_Pages'

# Check that NetworkManager is done, for network connectivity.
section_check 'NetworkManager'

# Check that Pacman is done, for updated packages.
section_check 'Pacman'

# Check that systemd-resolved is done, for resolving domain names.
section_check 'systemd-resolved'

# Check that systemd-timesyncd is done, for timestamps in logs.
section_check 'systemd-timesyncd'

# Ensure the openssh package is installed.
package_install 'openssh'

# Ensure the sshd configuration is installed.
file_install openssh/sshd_config /etc/ssh/sshd_config

# Ensure the sshd service is enabled and restarted.
systemctl enable sshd.service || exit
systemctl restart sshd.service || exit

# Ensure the ssh-audit package is installed, to help audit the configuration.
package_install 'ssh-audit'

# Run ssh-audit to audit the configuration of the local ssh server.
ssh-audit --level=warn localhost || exit

if [ "${_server}" = 'true' ]; then

    section_register 'Certbot'
    section_check 'NetworkManager'
    section_check 'Pacman'
    section_check 'systemd-resolved'
    section_check 'systemd-timesyncd'
    package_install 'certbot'
    systemctl stop httpd.service || exit
    for certbot_domain in ${_certbot_domains}; do
        if [ ! -d "/etc/letsencrypt/live/${certbot_domain}" ]; then
            certbot certonly --standalone \
                --non-interactive --agree-tos --email 'james@pole.net.nz' \
                --domain "${certbot_domain}" || exit
        fi
    done
    file_install certbot/certbot.service /etc/systemd/system/certbot.service || exit
    file_install certbot/certbot.timer /etc/systemd/system/certbot.timer || exit
    systemctl enable certbot.timer || exit
    systemctl restart certbot.timer || exit

    section_register 'Apache'
    section_check 'Certbot'
    section_check 'Manual_Pages'
    section_check 'NetworkManager'
    section_check 'Pacman'
    section_check 'systemd-resolved'
    section_check 'systemd-timesyncd'
    package_install 'apache'
    file_install apache/httpd.conf /etc/httpd/conf/httpd.conf
    systemctl enable httpd.service || exit
    systemctl restart httpd.service || exit

fi

if [ "${_laptop}" = 'true' ]; then
    section_register 'Multicast_DNS'
    section_check 'Pacman'
    package_install 'nss-mdns'
    file_install filesystem/nsswitch.conf /etc/nsswitch.conf
fi

#
# Section: Postfix
# Documentation: http://www.postfix.org/BASIC_CONFIGURATION_README.html#myorigin
# Documentation: http://www.postfix.org/SASL_README.html#client_sasl_enable
#

if [ "${_server}" = 'true' ]; then

    section_register 'Postfix'

    # Check that Manual_Pages is done, for manual pages.
    section_check 'Manual_Pages'

    # Check that NetworkManager is done, for network connectivity.
    section_check 'NetworkManager'

    # Check that Pacman is done, for updated packages.
    section_check 'Pacman'

    # Check that systemd-resolved is done, for resolving domain names.
    section_check 'systemd-resolved'

    # Check that systemd-timesyncd is done, for timestamps in logs.
    section_check 'systemd-timesyncd'

    # Ensure the postfix package is installed.
    package_install 'postfix'

    # Ensure the password file is installed.
    file_install postfix/sasl_passwd /etc/postfix/sasl_passwd root root 0640

    # Ensure the hashed password file has been generated.
    postmap /etc/postfix/sasl_passwd || exit

    # Ensure the domain name (i.e. pole.net.nz) is used for outgoing mail.
    postconf 'myorigin = $mydomain' || exit

    # Ensure client-side SMTP authentication is enabled.
    postconf 'smtp_sasl_auth_enable = yes' || exit

    # Ensure that outgoing mail is delivered over an encyrypted connection.
    postconf 'smtp_tls_security_level = encrypt' || exit

    # Ensure that plaintext passwords can be sent.
    postconf 'smtp_sasl_tls_security_options = noanonymous' || exit

    # Ensure outgoing mail is relayed via Fastmail.
    postconf 'relayhost = [smtp.fastmail.com]:submission' || exit

    # Ensure that the hashed password file is used for authentication.
    postconf 'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd' || exit

    # Ensure Postfix is enabled and reloaded (activating the configuration
    # defined above). If neccessary, start Postfix.
    systemctl enable postfix.service || exit
    systemctl reload-or-restart postfix.service || exit

fi

section_register 'Sudo'
section_check 'Manual_Pages'
section_check 'Pacman'
section_check 'systemd-timesyncd'
package_install 'sudo'
file_install sudo/sudoers /etc/sudoers root root 0440

section_register 'Vim'
section_check 'Manual_Pages'
section_check 'Pacman'
if [ "${_laptop}" = 'true' ]; then
    package_install 'gvim'
else
    package_install 'vim'
fi

#
# Section: Common_Packages
#

section_register 'Common_Packages'
section_check 'Manual_Pages'
section_check 'NetworkManager'
section_check 'Pacman'
section_check 'systemd-resolved'
section_check 'systemd-timesyncd'
section_check 'Vim'

package_install 'bash-completion'
package_install 'borg'
package_install 'fdupes'
package_install 'git'
package_install 'hunspell'
package_install 'hunspell-en_gb'
package_install 'iperf'
package_install 'jhead'
package_install 'rclone'
package_install 'rmlint'
package_install 'shellcheck'

if [ "${_laptop}" = 'true' ]; then
    section_register 'Laptop_Packages'
    section_check 'Common_Packages'
    section_check 'Manual_Pages'
    section_check 'Multicast_DNS'
    section_check 'NetworkManager'
    section_check 'Pacman'
    section_check 'systemd-resolved'
    section_check 'systemd-timesyncd'
    package_install 'cups'
    package_install 'firefox'
    package_install 'firefox-i18n-en-gb'
    package_install 'firefox-ublock-origin'
    package_install 'gdm'
    package_install 'gnome-boxes'
    package_install 'gnome-terminal'
    package_install 'hplip'
    package_install 'intel-media-sdk'
    package_install 'libreoffice-fresh'
    package_install 'libreoffice-fresh-en-gb'
    package_install 'nautilus'
    package_install 'sane-airscan'
    package_install 'signal-desktop'
    package_install 'simple-scan'
    package_install 'sushi'
    package_install 'telegram-desktop'
    package_install 'transmission-gtk'
fi

if [ "${_server}" = 'true' ]; then
    section_register 'Server_Packages'
    section_check 'Common_Packages'
    section_check 'Manual_Pages'
    section_check 'NetworkManager'
    section_check 'Pacman'
    section_check 'systemd-resolved'
    section_check 'systemd-timesyncd'
    package_install 'certbot'
    package_install 'screen'
    package_install 'sigal'
fi

section_register 'Locale'
section_check 'Common_Packages'
if [ "${_laptop}" = 'true' ]; then
    section_check 'Laptop_Packages'
fi
if [ "${_server}" = 'true' ]; then
    section_check 'Server_Packages'
fi
file_install glibc/locale.gen /etc/locale.gen
file_install systemd/locale.conf /etc/locale.conf
locale-gen || exit

print_info 'Finished.'
