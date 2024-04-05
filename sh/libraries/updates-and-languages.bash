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

# This is the configuration file for the current (master/trunk)
# development branch of WSUS Offline Update.

# Supported updates
updates_menu=(
    "w62-x64       Windows Server 2012, 64-bit"
    "w63           Windows 8.1, 32-bit"
    "w63-x64       Windows 8.1 / Server 2012 R2, 64-bit"
    "w100          Windows 10, 32-bit"
    "w100-x64      Windows 10 / Server 2016/2019, 64-bit"
    "o2k13         Office 2013, 32-bit"
    "o2k13-x64     Office 2013, 32-bit and 64-bit"
    "o2k16         Office 2016, 32-bit"
    "o2k16-x64     Office 2016, 32-bit and 64-bit"
    "all           All Windows and Office updates, 32-bit and 64-bit"
    "all-x86       All Windows and Office updates, 32-bit"
    "all-x64       All Windows and Office updates, 64-bit"
    "all-win       All Windows updates, 32-bit and 64-bit"
    "all-win-x86   All Windows updates, 32-bit"
    "all-win-x64   All Windows updates, 64-bit"
    "all-ofc       All Office updates, 32-bit and 64-bit"
    "all-ofc-x86   All Office updates, 32-bit"
)

# Internal Lists
list_all=( "w62-x64" "w63" "w63-x64" "w100" "w100-x64" "o2k13-x64" "o2k16-x64" )
list_all_x86=( "w63" "w100" "o2k13" "o2k16" )
list_all_x64=( "w62-x64" "w63-x64" "w100-x64" "o2k13-x64" "o2k16-x64" )
list_all_win=( "w62-x64" "w63" "w63-x64" "w100" "w100-x64" )
list_all_win_x86=( "w63" "w100" )
list_all_win_x64=( "w62-x64" "w63-x64" "w100-x64" )
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

# Options for Windows 8, 8.1 and 10
options_menu_windows=(
    "-includesp       Service Packs"
    "-includecpp      Visual C++ Runtime Libraries"
    "-includedotnet   .NET Frameworks"
    "-includewddefs   Windows Defender definition updates"
)

# Note: The option -includesp was reintroduced in WSUS Offline
# Update, Community Edition 12.4, but only for Windows 8.1. In the
# Linux download scripts, version 2.4, users may create a custom file
# ../exclude/custom/ExcludeList-SPs.txt to add service packs for all
# Windows and Office Versions.
#
# Options for all Office versions
options_menu_office=(
    "-includesp       Service Packs"
)

# Tables (string variables with multiple lines) are created from the
# indexed arrays above.
updates_table="$(printf '%s\n' "${updates_menu[@]}")"
languages_table="$(printf '%s\n' "${languages_menu[@]}")"
options_table="$(printf '%s\n' "${options_menu_windows[@]}")"

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
