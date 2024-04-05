# This file will be sourced by the shell bash.
#
# Filename: messages.bash
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
#     This file contains several functions, which print messages to the
#     screen and simultaneously write them to a log file. Bold text and
#     colors are used to highlight the log levels Info, Warning, Error,
#     Failure and Debug.
#
#     Such text formatting should only be used, if the output is printed
#     to a terminal emulator window or a Linux virtual console. It should
#     not be used, if the output is somehow redirected, for example,
#     if the download script is running as a cron job.
#
#     This is ensured by two tests:
#
#     - The test -t of POSIX shells ensures, that both file standard
#       output and error output are attached to a terminal.
#
#       How to detect if my shell script is running through a pipe?
#       https://stackoverflow.com/questions/911168/how-to-detect-if-my-shell-script-is-running-through-a-pipe
#
#     - The escape sequences for bold text and terminal colors are not
#       hard-coded, but determined with tput. This utility uses the
#       environment variable TERM, to check if bold text and colors can
#       be safely used.
#
#     But tput is overly restrictive in the use of terminal colors:
#
#     - It will only use colors, if TERM is set to either xterm-256color,
#       rxvt-256color or rxvt-unicode-256color.
#
#     - If TERM is set to xterm or xterm-color, only bold text will
#       be used.
#
#     - If TERM is set to "dumb", as in cron jobs, then no text formatting
#       will be applied.
#
#     Many terminal emulators simply set TERM to xterm, and they don't
#     provide any means to change this environment variable. But all
#     tested terminal emulators, including xterm itself, do support
#     colors. Then it should be safe, to change TERM from xterm and
#     xterm-color to xterm-256color, to get the expected results.
#
#     The same could be done with rxvt, but Debian already provides
#     different builds for rxvt, and the urxvt from package
#     rxvt-unicode-256color sets TERM to "rxvt-unicode-256color".
#
#     tput is also used to determine the height and width of the terminal
#     window, which are exported as the environment variables LINES and
#     COLUMNS. These environment variables are usually set in interactive
#     shells, but they are not inherited by scripts.
#
# Notes
#
#     Some terminal emulators like the MATE Terminal can run a custom
#     command instead of the standard shell. This can be used to specify
#     environment variables like:
#
#     /usr/bin/env TERM=xterm-256color bash
#
#     This may benefit other utilities as well. For example, some themes
#     for the Midnight Commander (mc) also require 256 colors.
#
#     The scripts update-generator.bash and download-updates.bash can
#     be launched in the same way:
#
#     /usr/bin/env TERM=xterm-256color ./update-generator.bash
#
#     or within a shell:
#
#     $ TERM=xterm-256color ./update-generator.bash
#
#     The environment variable TERM could also be set in startup files
#     like ~/.profile or ~/.bashrc, but this may give unexpected results:
#     Using TERM="xterm" in the Linux console will mess up the display of
#     the external utility "dialog", because the box drawing characters
#     are different.

# ========== Environment variables ========================================

# The test -t of POSIX shells ensures, that both standard output and
# error output (file descriptors 1 and 2) are attached to a terminal.
if [[ -t 1 && -t 2 ]]
then
    # Change TERM from xterm and xterm-color to xterm-256color to enable
    # color output in these terminal emulators.
    case "${TERM}" in
        xterm | xterm-color)
            TERM="xterm-256color"
            export TERM
        ;;
#        rxvt | rxvt-color)
#            TERM="rxvt-256color"
#            export TERM
#        ;;
        *)
            # Keep TERM and let tput figure out what to do
            :
        ;;
    esac

    # Get the dimensions of the terminal window
    COLUMNS="$(tput cols)"          || true
    LINES="$(tput lines)"           || true

    # Text styles and foreground (text) colors
    bold="$(tput bold)"             || true
    darkred="$(tput setaf 1)"       || true
    darkgreen="$(tput setaf 2)"     || true
    darkyellow="$(tput setaf 3)"    || true
    darkblue="$(tput setaf 4)"      || true
    brightred="$(tput setaf 9)"     || true
    brightgreen="$(tput setaf 10)"  || true
    brightyellow="$(tput setaf 11)" || true
    brightblue="$(tput setaf 12)"   || true

    # Other terminal commands
    reset_all="$(tput sgr0)"        || true
    clear_screen="$(tput clear)"    || true
fi

# If the height and width of the terminal window could not be determined,
# they will be set to default values.
COLUMNS="${COLUMNS:-80}"
LINES="${LINES:-24}"
export COLUMNS
export LINES

# If bold face and terminal colors cannot be used, then these variables
# will be set to empty strings.
bold="${bold:-}"
darkred="${darkred:-}"
darkgreen="${darkgreen:-}"
darkyellow="${darkyellow:-}"
darkblue="${darkblue:-}"
brightred="${brightred:-}"
brightgreen="${brightgreen:-}"
brightyellow="${brightyellow:-}"
brightblue="${brightblue:-}"
reset_all="${reset_all:-}"
clear_screen="${clear_screen:-}"

# ========== Global variables =============================================

# The global variables logfile and debug should always be set by the
# scripts, which import (source) this library. For example, ${logfile}
# is set to "../log/download.log" by the scripts download-updates.bash
# and update-generator.bash.
#
# To make this file more self-contained and supply reasonably defaults
# for other scripts, ${logfile} is set to "messages.log", and ${debug}
# is set to "disabled" with standard parameters.

logfile="${logfile:-messages.log}"
debug="${debug:-disabled}"

# ========== Functions ====================================================

# If long lines are displayed in a terminal window, then the terminal
# emulator often breaks lines within words, which makes the text hard
# to read. This can be prevented by wrapping the text to the length of
# the terminal window with fold --spaces --width="${COLUMNS}".
#
# TODO: Terminal colors influence the line width. Lines with colors are
# shorter than those without.
#
# printf '%s\n' should be used instead of echo, except for simple messages
# without escape characters or variables.

function show_message ()
{
    printf '%s\n' "$*" | fold -s -w "${COLUMNS}"
    return 0
}

# The function log_message does not insert the date or a log level. It
# can be used to duplicate the output of external commands like hashdeep
# and curl.
function log_message ()
{
    printf '%s\n' "$*" | fold -s -w "${COLUMNS}"
    printf '%s\n' "$*" >> "${logfile}"
    return 0
}

# Terminal emulators use bold text for bright colors by default. This can
# be disabled in xterm and KDE Konsole, but not in most other terminal
# emulators. To ensure the expected style, "bold" should be set anyway.
#
# Note: The command date should use UTC most of the time, because web
# servers return the file modification dates in UTC. In log files,
# the local time should be used, though.
function log_info_message ()
{
    printf '%s\n' "${bold}${brightgreen}Info:${reset_all} $*" | fold -s -w "${COLUMNS}"
    printf '%s\n' "$(date "+%F %T") - Info: $*" >> "${logfile}"
    return 0
}

# Warnings are not errors, but unusual conditions, which should be
# examined.
function log_warning_message ()
{
    printf '%s\n' "${bold}${brightyellow}Warning:${reset_all} $*" | fold -s -w "${COLUMNS}"
    printf '%s\n' "$(date "+%F %T") - Warning: $*" >> "${logfile}"
    return 0
} 1>&2

# Errors are runtime errors from wget or aria2, which may be
# recovered. Temporary download errors happen all the time. Some downloads
# like the virus definition files may fail even after ten tries. Such
# errors are reported and written to the log file, but then the script
# should continue anyway.
function log_error_message ()
{
    printf '%s\n' "${bold}${brightred}Error:${reset_all} $*" | fold -s -w "${COLUMNS}"
    printf '%s\n' "$(date "+%F %T") - Error: $*" >> "${logfile}"
    return 0
} 1>&2

function log_file_integrity_verification_error ()
{
    printf '%s\n' "${bold}${brightred}File integrity verification error:${reset_all} $*" | fold -s -w "${COLUMNS}"
    printf '%s\n' "$(date "+%F %T") - File integrity verification error: $*" >> "${logfile}"
    return 0
} 1>&2

# Failures are programming errors of the type "This should never happen".
function fail ()
{
    printf '%s\n' "${bold}${brightred}Failure:${reset_all} $*" | fold -s -w "${COLUMNS}"
    printf '%s\n' "$(date "+%F %T") - Failure: $*" >> "${logfile}"
    show_backtrace
    echo "The script will now exit"
    exit 1
} 1>&2

# Enabling the option debug provides more output for some functions,
# but this is only meant for development.
#
# The first parameter is the debug message. Additional parameters are
# printed one per line. These could be arrays or the output of other
# commands.
function log_debug_message ()
{
    local message="$1"
    shift 1

    if [[ "${debug}" == "enabled" ]]
    then
        if (( $# > 0 ))
        then
            printf '%s\n' "${bold}${brightblue}Debug:${reset_all} ${message}" "$@" | fold -s -w "${COLUMNS}"
            printf '%s\n' "$(date "+%F %T") - Debug: ${message}" "$@" >> "${logfile}"
        else
            printf '%s\n' "${bold}${brightblue}Debug:${reset_all} ${message}" | fold -s -w "${COLUMNS}"
            printf '%s\n' "$(date "+%F %T") - Debug: ${message}" >> "${logfile}"
        fi
    fi
    return 0
} 1>&2

function show_backtrace ()
{
    local previous_command=""
    local -i depth="0"

    # The indexed array FUNCNAME has the calling chain of all functions,
    # with the top level code called "main". This is why there is no
    # function "main" in the script.
    printf '%s\n' "Backtrace: ${FUNCNAME[*]}"

    # The bash internal command "caller" moves backwards through the
    # calling chain. It is typically used with a bash debugger, but can
    # also be used alone.
    while previous_command="$(caller ${depth})"
    do
        printf '%s\n' "Caller ${depth}: ${previous_command}"
        depth="$(( depth + 1 ))"
    done

    return 0
} 1>&2

# function ask_question ()
#
# Print a question ($1) and an optional help_text ($2), then show the
# prompt [Y/n]. If only return is pressed, "Y" will be the default answer.
#
# For a discussion see
# https://stackoverflow.com/questions/226703/how-do-i-prompt-for-input-in-a-linux-shell-script/22893526
#
# The second parameter with the help text is optional; a standard value
# is supplied to prevent error messages, if the shell option -u is used.
function ask_question ()
{
    local question="$1"
    local help_text="${2:-}"
    local answer=""

    show_message "${question}"
    if [[ -n "${help_text}" ]]
    then
        show_message "${help_text}"
    fi

    while true
    do
        read -r -p "[Y/n]: " answer
        # Assume "Yes", if only return is pressed
        case "${answer:-Y}" in
            [Yy]*)
                return 0
            ;;
            [Nn]*)
                return 1
            ;;
            *)
                echo "Please enter \"Yes\" or \"no\" or simply hit return to select the default answer."
            ;;
        esac
    done
    return 0
}

return 0
