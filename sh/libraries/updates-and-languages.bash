# This file will be sourced by the shell bash.
#
# Filename: updates-and-languages.bash
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
#     This file defines menus and tables for the updates, languages and
#     available options.
#
#     Menus and tables basically provide the same information, but in a
#     different format: menus are indexed arrays, while tables are text
#     variables with multiple lines.
#
#
#     Menus for the script update-generator.bash
#
#     Menus are implemented as indexed arrays. They are used to create
#     simple selection dialogs with the bash built-in command "select".
#
#     Each array element consists of a name and description. It can be
#     split into single fields with "read -r". As usual with "read",
#     the last variable receives the remainder of the line. This is
#     used here to split the line into two fields, without needing any
#     additional field delimiters like commas or semicolons:
#
#     read -r update_name   update_description   <<< "${line}"
#     read -r language_name language_description <<< "${line}"
#     read -r option_name   option_description   <<< "${line}"
#
#
#     Tables for the script download-updates.bash
#
#     Tables are created by printing the indexed arrays. They can be
#     searched just like text files, by replacing a file reference with a
#     "here-string". The function name_to_description reads the table in
#     a loop and returns the description, if the specified name was found.

# ========== Configuration ================================================

# This is the configuration file for the development branch 11.9.x ESR
# (extended support release) of WSUS Offline Update.
#
# This branch was created to support:
# - Windows Server 2008
# - Windows 7 / Server 2008 R2
#
# WSUS Offline Update 12.0 and later should be used for all other
# updates. New features like the fine selection of Windows 10 versions
# are only added to the current (master/trunk) versions of WSUS Offline
# Update.

# Supported updates
#
# Windows Server 2008, based on Windows Vista, is available in both
# 32-bit and 64-bit versions.
#
# Windows Server 2008 R2, based on Windows 7, "is the first 64-bit–only
# operating system released from Microsoft."
#
# - https://en.wikipedia.org/wiki/Windows_Server_2008
# - https://en.wikipedia.org/wiki/Windows_Server_2008_R2

updates_menu=(
    "w60           Windows Server 2008, 32-bit"
    "w60-x64       Windows Server 2008, 64-bit"
    "w61           Windows 7, 32-bit"
    "w61-x64       Windows 7 / Server 2008 R2, 64-bit"
    "w62-x64       Windows Server 2012, 64-bit              (deprecated)"
    "w63           Windows 8.1, 32-bit                      (deprecated)"
    "w63-x64       Windows 8.1 / Server 2012 R2, 64-bit     (deprecated)"
    "w100          Windows 10, 32-bit                       (deprecated)"
    "w100-x64      Windows 10 / Server 2016/2019, 64-bit    (deprecated)"
    "o2k13         Office 2013, 32-bit                      (deprecated)"
    "o2k13-x64     Office 2013, 32-bit and 64-bit           (deprecated)"
    "o2k16         Office 2016, 32-bit                      (deprecated)"
    "o2k16-x64     Office 2016, 32-bit and 64-bit           (deprecated)"
    "all           All Windows and Office updt, 32/64-bit   (deprecated)"
    "all-x86       All Windows and Office updates, 32-bit   (deprecated)"
    "all-x64       All Windows and Office updates, 64-bit   (deprecated)"
    "all-win       All Windows updates, 32-bit and 64-bit   (deprecated)"
    "all-win-x86   All Windows updates, 32-bit              (deprecated)"
    "all-win-x64   All Windows updates, 64-bit              (deprecated)"
    "all-ofc       All Office updates, 32-bit and 64-bit    (deprecated)"
    "all-ofc-x86   All Office updates, 32-bit               (deprecated)"
)

# Internal Lists
list_all=( "w60" "w60-x64" "w61" "w61-x64" "w62-x64" "w63" "w63-x64" "w100" "w100-x64" "o2k13-x64" "o2k16-x64" )
list_all_x86=( "w60" "w61" "w63" "w100" "o2k13" "o2k16" )
list_all_x64=( "w60-x64" "w61-x64" "w62-x64" "w63-x64" "w100-x64" "o2k13-x64" "o2k16-x64" )
list_all_win=( "w60" "w60-x64" "w61" "w61-x64" "w62-x64" "w63" "w63-x64" "w100" "w100-x64" )
list_all_win_x86=( "w60" "w61" "w63" "w100" )
list_all_win_x64=( "w60-x64" "w61-x64" "w62-x64" "w63-x64" "w100-x64" )
list_all_ofc=( "o2k13-x64" "o2k16-x64" )
list_all_ofc_x86=( "o2k13" "o2k16" )

# Supported Languages
#
# Recent Windows versions use global/multilingual updates, but the
# installers for Internet Explorer and .NET Frameworks are still
# localized. Therefore, the approach for the Linux scripts is to display
# the language selection for all updates.
languages_menu=(
    "deu   German"
    "enu   English"
    "ara   Arabic"
    "chs   Chinese (Simplified)"
    "cht   Chinese (Traditional)"
    "csy   Czech"
    "dan   Danish"
    "nld   Dutch"
    "fin   Finnish"
    "fra   French"
    "ell   Greek"
    "heb   Hebrew"
    "hun   Hungarian"
    "ita   Italian"
    "jpn   Japanese"
    "kor   Korean"
    "nor   Norwegian"
    "plk   Polish"
    "ptg   Portuguese"
    "ptb   Portuguese (Brazil)"
    "rus   Russian"
    "esn   Spanish"
    "sve   Swedish"
    "trk   Turkish"
)

# Options for Windows Vista and Windows 7.
#
# The original Windows Defender is preinstalled in Windows Vista and
# 7. It can be replaced by installing Security Essentials.
#
# These options are also used for the internal lists all, all-x86,
# all-x64, all-win, all-win-x86, and all-win-x64.
options_menu_windows_vista=(
    "-includesp        Service Packs"
    "-includecpp       Visual C++ Runtime Libraries"
    "-includedotnet    .NET Frameworks"
    "-includewddefs    Windows Defender Definitions for Windows Vista and 7"
    "-includemsse      Microsoft Security Essentials"
)

# Options for Windows 8, 8.1 and 10
options_menu_windows_8=(
    "-includesp        Service Packs"
    "-includecpp       Visual C++ Runtime Libraries"
    "-includedotnet    .NET Frameworks"
    "-includewddefs8   Windows Defender Definitions for Windows 8 - 10"
)

# Options for all Office versions
options_menu_office=(
    "-includesp        Service Packs"
)

# All options, used for parsing the command-line parameters
options_menu=(
    "-includesp        Service Packs"
    "-includecpp       Visual C++ Runtime Libraries"
    "-includedotnet    .NET Frameworks"
    "-includewddefs    Windows Defender Definitions for Windows Vista and 7"
    "-includemsse      Microsoft Security Essentials"
    "-includewddefs8   Windows Defender Definitions for Windows 8 - 10"
)

# Tables (string variables with multiple lines) are created from the
# indexed arrays above.
updates_table="$(printf '%s\n' "${updates_menu[@]}")"
languages_table="$(printf '%s\n' "${languages_menu[@]}")"
options_table="$(printf '%s\n' "${options_menu[@]}")"

# ========== Functions ====================================================

# The function name_to_description searches one of the tables created
# above for a specified name.
#
# If the name was found, then the corresponding description is printed
# to standard output and the result code is set to "0".
#
# If the name was NOT found, an empty string is returned, and the result
# code is set to "1".

function name_to_description ()
{
    local searched_name="$1"
    local searched_table="$2"
    local name=""
    local description=""

    while read -r name description
    do
        if [[ "${name}" == "${searched_name}" ]]
        then
            printf '%s\n' "${description}"
            return 0
        fi
    done <<< "${searched_table}"

    echo ""
    return 1
}

return 0
