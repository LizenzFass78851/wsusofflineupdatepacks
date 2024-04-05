# This file will be sourced by the shell bash.
#
# Filename: error-counter.bash
#
# Copyright (C) 2018-2021 Hartmut Buhrmester
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
#     Using an automatic error detection with the shell option errexit
#     or a trap on ERR has some problems:
#
#     If a function returns a result code other than "0", it will be
#     treated like an error in an external command, and the script
#     will immediately exit. The function call could be embedded in
#     a conditional expression, but this doesn't just mask the result
#     code, but also disables the option errexit in the whole function
#     body. Once all functions are embedded in conditional expressions,
#     the shell option errexit will be disabled everywhere.
#
#     This means, that functions should always return 0. The result code
#     can not be used anymore to indicate errors within the function.
#
#     One workaround would be to use a global variable as an error
#     counter. At the start of a function, the current error count can
#     be saved to a local variable. Runtime errors within the function
#     will increment the global counter. At the end of the function, the
#     current error count can be compared to the previously saved error
#     count: If the current count is larger, then some error has occurred.
#
#     Using local variables for the previous state, this also works with
#     nested functions.
#
#     This library provides the global variable and some functions,
#     which use it.

runtime_errors="0"

function get_error_count ()
{
    echo "${runtime_errors}"
    return 0
}

function increment_error_count ()
{
    runtime_errors="$(( runtime_errors + 1 ))"
    return 0
}

function same_error_count ()
{
    local -i initial_errors="$1"

    if (( runtime_errors == initial_errors ))
    then
        return 0  # no error
    else
        return 1  # some runtime errors
    fi
}

function get_error_difference ()
{
    local -i initial_errors="$1"
    local -i error_difference="0"

    error_difference="$(( runtime_errors - initial_errors ))"
    echo "${error_difference}"
    return 0
}

return 0
