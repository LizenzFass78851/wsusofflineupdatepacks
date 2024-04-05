# This file will be sourced by the shell bash.
#
# Filename: desktop-integration.bash
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
#     This file implements a function to put outdated files into the
#     trash, rather than deleting them directly. With the package
#     trash-cli, this actually works without any graphical desktop
#     environment.
#
#     In Linux, the local trash is the directory
#     ${HOME}/.local/share/Trash. External drives use a directory
#     .Trash-1000 at the root level of the partition. The number "1000"
#     is the user id of the first regular user in Debian. It would be
#     "500" for Fedora.
#
#     gvfs-trash and trash-put may fail, if the file system does not
#     support a trash, for example, because the directory /.Trash-1000
#     could not be created. Then the files are deleted directly with rm.
#
#     The global variable ${linux_trash_handler} is set in the file
#     20-check-needed-applications.bash.

function trash_file ()
{
    local pathname="$1"
    local filename="${pathname##*/}"

    if [[ -f "${pathname}" ]]
    then
        # Try a Linux trash handler like "gio trash", gvfs-trash or
        # trash-put, if available
        if [[ -n "${linux_trash_handler}" ]]
        then
            # The variable ${linux_trash_handler} must not be quoted
            # anymore, because it may expand to "gio trash".
            if ${linux_trash_handler} "${pathname}"
            then
                log_info_message "The file ${filename} was moved to trash."
            else
                # The trash directory may not be available, if wsusoffline
                # is installed on an external drive. Then moving files
                # to the trash may fail. In this case, the file needs
                # to be deleted directly.
                if rm "${pathname}"
                then
                    log_info_message "The file ${filename} was deleted directly."
                else
                    # Deleting a file with rm should always work. If this
                    # fails, it may indicate more underlying problems,
                    # e.g. with file ownership and permissions, or with
                    # virus scanners, which block access to the file
                    # for other applications.
                    fail "The file ${filename} could not be deleted."
                fi
            fi
        else
            # Delete the file directly
            if rm "${pathname}"
            then
                log_info_message "The file ${filename} was deleted directly."
            else
                fail "The file ${filename} could not be deleted."
            fi
        fi
    else
        log_error_message "${FUNCNAME[0]}: File ${pathname} was not found"
    fi

    return 0
}

return 0
