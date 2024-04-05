# This file will be sourced by the shell bash.
#
# Filename: 71-make-snapshot.bash
#
# Copyright (C) 2016-2021 Hartmut Buhrmester
#                         <wsusoffline-scripts-xxyh@hartmut-buhrmester.de>
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
#     This task creates a snapshot of the client directory. Files will
#     not be copied but hard-linked. Then the snapshot won't use any disk
#     space, but it may still serve as a backup, if all other copies of
#     the same file are deleted.
#
#     This is similar to the rotating backups described in
#     http://www.mikerubel.org/computers/rsync_snapshots/ .
#
# Usage
#
#     Move this file to the directory download-updates-tasks, to be run
#     after all other tasks.

# ========== Commands =====================================================

pushd .. > /dev/null
# The option -a, --archive copies directories recursively and preserves
# all available attributes.
# The option -l, --link creates hard links instead of copying the files.
cp -a -l "client" "client_$(date '+%F_%H-%M-%S')"
popd > /dev/null || exit 0
