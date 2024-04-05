# This file will be sourced by the shell bash.
#
# Filename: 20-show-selection-dialogs.bash
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
#     This file displays the selection dialogs for the update, language
#     and download options. It uses the built-in command "select" of the
#     bash. This is easy to use, but it doesn't allow multiple selections.
#
#     The menus are provided by the file updates-and-languages.bash. They
#     are used by this file and by the file 10-parse-command-line.bash
#     for the download script.

# ========== Global variables =============================================

update_name=""
download_command=( "./download-updates.bash" )

# ========== Functions ====================================================

function show_selection_dialogs ()
{
    [[ "${debug}" == "disabled" ]] && echo "${clear_screen}"
    select_update

    [[ "${debug}" == "disabled" ]] && echo "${clear_screen}"
    select_language

    [[ "${debug}" == "disabled" ]] && echo "${clear_screen}"
    select_options

    [[ "${debug}" == "disabled" ]] && echo "${clear_screen}"
    confirm_download_command "${download_command[@]}"
    return 0
}


function select_update ()
{
    local menu_selection=""
    # update_name is defined globally
    local update_description=""

    echo "Update selection"
    echo "----------------"
    PS3="Please select your update: "
    select menu_selection in "${updates_menu[@]}"
    do
        if [[ -n "${menu_selection}" ]]
        then
            break
        else
            echo "Please try again!"
        fi
    done
    PS3=""

    read -r update_name update_description <<< "${menu_selection}"
    download_command+=( "${update_name}" )

    log_debug_message "Update name:  ${update_name}"
    log_debug_message "Description:  ${update_description}"
    log_debug_message "Command:      ${download_command[*]}"
    return 0
}


function select_language ()
{
    local menu_selection=""
    local language_name=""
    local language_description=""

    echo "Language selection"
    echo "------------------"
    PS3="Please select your language: "
    select menu_selection in "${languages_menu[@]}"
    do
        if [[ -n "${menu_selection}" ]]
        then
            break
        else
            echo "Please try again!"
        fi
    done
    PS3=""

    read -r language_name language_description <<< "${menu_selection}"
    download_command+=( "${language_name}" )

    log_debug_message "Language name: ${language_name}"
    log_debug_message "Description:   ${language_description}"
    log_debug_message "Command line:  ${download_command[*]}"
    return 0
}


function select_options ()
{
    local valid_options=()
    local current_option=""
    local option_name=""
    local option_description=""

    case "${update_name}" in
        w62-x64 | w63 | w63-x64 | w100 | w100-x64 \
        | all | all-x86 | all-x64 | all-win | all-win-x86 | all-win-x64)
            valid_options+=( "${options_menu_windows[@]}" )
        ;;
        o2k13 | o2k13-x64 | o2k16 | o2k16-x64 | all-ofc | all-ofc-x86)
            valid_options+=( "${options_menu_office[@]}" )
        ;;
        *)
            fail "Update ${update_name} was not found."
        ;;
    esac

    echo "Optional downloads"
    echo "------------------"
    if (( "${#valid_options[@]}" > 0 ))
    then
        for current_option in "${valid_options[@]}"
        do
            read -r option_name option_description <<< "${current_option}"

            if ask_question "Include ${option_description}?"
            then
                download_command+=( "${option_name}" )
            fi
        done
    fi
    return 0
}


function confirm_download_command ()
{
    echo "Summary"
    echo "-------"
    echo "The interactive setup is complete. The command to download the updates is:"
    show_message "${download_command[*]}"
    echo ""

    if ask_question "Do you wish to execute is now?"
    then
        # The temporary directory of the script update-generator.exe
        # must be removed at this point. The script download-updates.bash
        # will create a new temporary directory with a different name.
        if [[ -d "${temp_dir}" ]]
        then
            #echo "Cleaning up temporary files ..."
            rm -r "${temp_dir}"
        fi
        exec "${download_command[@]}"
    fi
    return 0
}

# ========== Commands =====================================================

show_selection_dialogs
return 0
