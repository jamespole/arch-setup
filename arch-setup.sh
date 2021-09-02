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

if [ $UID -ne 0 ]; then
    echo 'Run this script as root.'
    exit 1
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
    echo -n "[$SECONDS] ${_self_name}:"
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
# Start of sections.
#

section_register 'Pacman'
pacman --sync --refresh --sysupgrade --quiet --noconfirm

print_info "Finished."
