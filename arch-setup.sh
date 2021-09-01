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
    exit
fi

#
# Internal variables.
#

_self_name='arch-setup'

#
# Fuctions for printing coloured output.
#

print_colour () {
    if [ $# != 2 ]; then
        echo 'Function print_colour() expects 2 arguments.'
        exit
    fi
    echo -e "\033[0;${1}m[$SECONDS] ${_self_name}:\033[0m $2"
}

print_info () {
    if [ $# != 1 ]; then
        echo 'Function print_info() expects 1 argument.'
        exit
    fi
    print_colour 33 "$1"
}

print_section () {
    if [ $# != 1 ]; then
        echo 'Function print_section() expects 1 argument.'
        exit
    fi
    print_colour 35 "$1"
}

print_success () {
    if [ $# != 1 ]; then
        echo 'Function print_success() expects 1 argument.'
        exit
    fi
    print_colour 32 "$1"
}
