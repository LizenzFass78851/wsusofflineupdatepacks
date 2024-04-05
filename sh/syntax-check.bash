#!/usr/bin/env bash

# Filename: syntax-check.bash
#
# Copyright (C) 2021 Hartmut Buhrmester
#                    <wsusoffline-scripts-xxyh@hartmut-buhrmester.de>
#
# License
#
#     This file is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published
#     by the Free Software Foundation, either version 3 of the License,
#     or (at your option) any later version.
#
#     This file is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#     General Public License for more details.
#
#     You should have received a copy of the GNU General
#     Public License along with this program.  If not, see
#     <http://www.gnu.org/licenses/>.
#
# Description
#
#     This script does a quick syntax check, using both bash and the
#     utility shellcheck. It is used for development.


# Shell options
set -o nounset
set -o errexit
set -o pipefail
shopt -s nullglob

# Environment variables
export LC_ALL=C

# Change to the installation directory
cd "$(dirname "$(readlink -f "$0")")" || exit 1


# bash itself can do a quick syntax check.
#
# Note: The option -execdir {} + is a GNU find extension, which can add
# multiple parameters to the command-line, similar to xargs.

printf '%s\n' "Syntax check with bash..."
find . -type f -name "*.bash" -execdir bash -n "{}" +

# Disable two tests in shellcheck:
#
# SC2034 will report numerous warnings like:
#
# ./60-main-updates.bash:776:41: warning: skip_rest appears unused. Verify use (or export if used externally). [SC2034]
#
# Some of the reported variables are really unused, but most of them
# are used in other files.
#
# SC2154 is the opposite of SC2034:
#
# ./20-start-logging.bash:78:32: warning: script_name is referenced but not assigned. [SC2154]
#
# This usually means, that the variables are defined in other
# files. In this example, script_name is set by the two main scripts,
# download-updates.bash and update-generator.bash.
#
# These warnings are somewhat typical for scripts, which are sourced
# from other scripts. shellcheck can follow sourced files, but then each
# file must be listed individually by name. It doesn't work, if files
# are sourced in a loop as in the main scripts update-generator.bash
# and download-updates.bash.

printf '%s\n' "Syntax check with shellcheck..."
find . -type f -name "*.bash" -execdir shellcheck --exclude=SC2034,SC2154 --format=gcc --shell=bash --external-sources "{}" +

printf '%s\n' "All done, exiting..."
exit 0
