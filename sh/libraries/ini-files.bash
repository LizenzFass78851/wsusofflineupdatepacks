# This file will be sourced by the shell bash.
#
# Filename: ini-files.bash
#
# Copyright (C) 2019-2021 Hartmut Buhrmester
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
#     Settings are pairs of keys and values. The general format is:
#
#     key=value
#
#     Settings files can be written and maintained using two different
#     approaches:
#
#     1. Preferences files can be written as bash scripts, which are
#        directly imported (sourced) by the shell. This implies, that
#        settings must be valid variable assignments according to the
#        bash syntax:
#
#        - The keys must be valid parameter names, consisting of
#          alphanumerical characters and underscores only.
#        - The values must be quoted as needed, using single or double
#          quotation marks.
#        - The file can be thoroughly commented to explain all settings.
#
#        Preferences files are usually provided as templates, which must
#        be copied before use. They can only be edited manually. Such
#        preferences files are used for permanent settings. A typical
#        example would be the preferences file of the bash itself,
#        ~/.bashrc. The template /etc/skel/.bashrc is copied to the home
#        directory, when a new user is created.
#
#     2. Settings files can also be written as ini files, which are only
#        read and written with special functions. Then these files don't
#        necessarily need to adhere to the bash syntax:
#
#        - Strings like "w63-x64" can be used as keys, although they
#          would not be valid parameter names.
#        - The values are not quoted, even if they consist of several
#          words. Everything from the equals sign "=" to the end of the
#          line will be the value.
#        - Typically, there are no comments in the file.
#
#        Ini files are automatically created on the first run. They are
#        typically used to keep settings between runs.
#
#     In both cases, settings files should be optional, and they may be
#     deleted at any point to start from scratch. Then the application
#     must provide default values for all settings.
#
#     In the Linux download scripts, both approaches are used:
#
#     - The file preferences-template.bash is the template for the
#       file preferences.bash. The template must be copied or renamed
#       to preferences.bash, before it can be used. This is meant as a
#       simple way to protect customized settings from being overwritten
#       on each update. It can then be edited to set some permanent
#       settings like proxy servers or to enable and disable parts of
#       the Linux download scripts.
#
#     - The script update-generator.bash now uses the file
#       update-generator.ini, to keep the current settings between
#       runs. It is created and maintained automatically.
#
#     This file provides two functions for the handling of ini files. It
#     does not implement sections [...] within the file. New settings
#     are always appended to the end of the file.

# ========== Functions ====================================================

# The function read_setting reads a single setting from a settings
# file. If the key was found, its value will be printed to standard
# output, and the function return with success.
#
# Result codes:
#
# 0  The settings file exists, and the key was found. The value (possibly
#    an empty string) will be written to standard output.
# 1  The settings file was not found.
# 2  The settings file exists, but the key was not found.

function read_setting ()
{
    local settings_file="$1"
    local key="$2"
    local value=""
    local -i result_code="0"

    if [[ -f "${settings_file}" ]]
    then
        # Search for "${key}=" at the beginning of the line
        #
        # For files with Windows line endings, the trailing carriage
        # return must be removed from the result. This is done by the
        # wrapper function grep_dos.
        if value="$(grep_dos -e "^${key}=" "${settings_file}")"
        then
            # Delete "${key}=" from the beginning of the string. The
            # rest of the line is the value from the settings file.
            value="${value/#${key}=/}"
        else
            log_debug_message "The key ${key} was not found in the settings file ${settings_file}."
            result_code="2"
        fi
    else
        log_debug_message "The settings file ${settings_file} was not found."
        result_code="1"
    fi

    # Print the value to standard output
    printf '%s\n' "${value}"
    return "${result_code}"
}


# The function write_setting writes a single setting to the settings
# file. If the settings file does not exist yet, it will be created at
# this point. The setting is only written, if the key does not exist yet,
# or if the value has changed.

function write_setting ()
{
    local settings_file="$1"
    local key="$2"
    local new_value="$3"
    local old_value=""

    # Create settings file, if it does not exist yet.
    if [[ ! -f "${settings_file}" ]]
    then
        touch "${settings_file}"
    fi

    # Search for "${key}=" at the beginning of the line.
    if old_value="$(grep_dos -e "^${key}=" "${settings_file}")"
    then
        # Delete "${key}=" from the beginning of the line. The rest of
        # the line is the old value from the settings file.
        old_value="${old_value/#${key}=/}"

        if [[ "${old_value}" == "${new_value}" ]]
        then
            log_debug_message "No changes for ${key} ..."
        else
            log_debug_message "Changing ${key} from \"${old_value}\" to \"${new_value}\" ..."
            # There are slight differences, how sed "inline" works in
            # FreeBSD 12.1 and GNU/Linux:
            #
            # The FreeBSD sed always expects a file extension for a
            # backup file after the option -i, even if it is only an empty
            # string. Otherwise, the next two parameters are interpreted
            # as the file extension and the sed script command. Then
            # the FreeBSD sed may print an error message like:
            #
            # $ sed -i "s/w63=off/w63=on/" update-generator.ini
            # sed: 1: "update-generator.ini": invalid command code u
            #
            # It is possible to specify an empty string as a file
            # extension, like:
            #
            # $ sed -i "" "s/w63=off/w63=on/" update-generator.ini
            #
            # Then FreeBSD sed will not report an error, and the script
            # command is evaluated as expected.
            #
            # With the GNU/Linux sed, it is just the other way around:
            # The first version works, but the second version creates
            # an error.
            #
            # The only way, that works for both FreeBSD and GNU/Linux sed,
            # is to actually provide a file extension for backup files
            # (which will be removed afterwards):
            #
            # $ sed -i.bak "s/w63=off/w63=on/" update-generator.ini
            #
            # TODO: This may be solved better by using the option -e,
            # to explicitly set the sed script.
            #
            # The search pattern for sed is anchored to the beginning of
            # the line with the character "^". The end-of-line character
            # "$" should not be used anymore: In files with Windows
            # line endings, the complete line would include a trailing
            # carriage return, which should NOT become part of the search
            # pattern. Replacing the text up to, but not including the
            # carriage return, works as expected.
            #
            # The search and replacement patterns assume, that the values
            # are NOT quoted.
            #
            # ETags contain two quotation marks and one slash. The
            # quotation marks are handled well, but the slash causes
            # the command "s/regular expression/replacement/flags"
            # to break. Using "s#regular expression#replacement#flags"
            # does work in this case. Actually, this is the example from
            # the FreeBSD sed manual page for handling path names.
            sed -i.bak -e "s#^${key}=${old_value}#${key}=${new_value}#" "${settings_file}"
            rm -f "${settings_file}.bak"
        fi
    else
        # If the key was NOT found in the settings file, then the setting
        # is appended to the end of the file. This is normal for newly
        # created files, but it also allows to add new settings to
        # existing files in newer versions of the Linux download scripts.
        #
        # TODO: This does not work for files, where sections like
        # [Installation] and [Miscellaneous] are really used.
        log_debug_message "Appending \"${key}=${new_value}\" to ${settings_file} ..."
        printf '%s\n' "${key}=${new_value}" >> "${settings_file}"
    fi

    return 0
}

# ========== Commands =====================================================

return 0
