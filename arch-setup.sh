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
else
    _laptop=0
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
install --backup=numbered --compare --owner=root --group=root --mode=0644 \
    pacman/pacman.conf /etc/pacman.conf || exit
install --backup=numbered --compare --owner=root --group=root --mode=0644 \
    pacman/mirrorlist /etc/pacman.d/mirrorlist || exit
pacman --sync --refresh --sysupgrade --quiet --noconfirm || exit
pacman --files --noconfirm --refresh --quiet || exit

section_register 'Vim'
section_check 'Pacman'
if [ "${_laptop}" = 'true' ]; then
    package_install 'gvim'
else
    package_install 'vim'
fi

section_register 'Common_Packages'
section_check 'Pacman'
package_install 'bash-completion'
package_install 'jhead'
package_install 'man-db'
package_install 'man-pages'

if [ "${_laptop}" = 'true' ]; then
    section_register 'Laptop_Packages'
    section_check 'Pacman'
    package_install 'firefox'
    package_install 'firefox-i18n-en-gb'
    package_install 'firefox-ublock-origin'
    package_install 'gdm'
    package_install 'gnome-terminal'
    package_install 'libreoffice-fresh'
    package_install 'libreoffice-fresh-en-gb'
    package_install 'signal-desktop'
    package_install 'simple-scan'
    package_install 'transmission-gtk'
fi

print_info 'Finished.'
