# This file will be sourced by the shell bash.
#
# Filename: 10-remove-obsolete-scripts.bash
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
#     During the development of the new Linux scripts, tasks and
#     libraries sometimes need to be replaced or renumbered. Then
#     the first task would be to delete obsolete files of previous
#     versions. Therefore, this new task is inserted as the first file
#     in the directory common-tasks.

# ========== Functions ====================================================

# WSUS Offline Update, Community Editions CE-11.9.1 and CE-12.0 are
# new development branches. Both came with the Linux download scripts,
# version 1.19.
#
# Obsolete files from older versions are only considered, if they are
# still found in version 1.19. This refers to two renamed files and
# folders: 71-make-shapshot.bash and licence. They were renamed in version
# 1.16, but the changes never made it into svn/Trak at wsusoffline.net.
#
# Version 1.19 of the Linux download scripts is the common predecessor
# of versions 1.19.1-ESR and 1.20.

function remove_obsolete_scripts ()
{
    local old_name=""
    #local new_name=""
    local -a file_list=()
    local pathname=""
    local filename=""

    # Obsolete files in Linux download scripts, version 1.16
    #
    # The file 71-make-shapshot.bash was spelled wrong, but this didn't
    # get noticed for a long time. But screen fonts have a large x-height
    # and only short ascenders, and then "n" and "h" can look pretty
    # similar.
    #
    # The filename was corrected to 71-make-snapshot.bash in the Linux
    # download scripts, version 1.16.
    # - https://forums.wsusoffline.net/viewtopic.php?f=9&t=10057
    #
    # In WSUS Offline Update, version 11.9.1-ESR at wsusoffline.net,
    # there were two files:
    #
    # ./available-tasks/71-make-shapshot.bash
    # ./available-tasks/71-make-snapshot.bash
    #
    # This was finally solved in WSUS Offline Update, Community Editions
    # 11.9.1 and 12.0. The old file, if still present, can be deleted:

    old_name="71-make-shapshot.bash"
    rm -f "./available-tasks/${old_name}"

    # The noun "licence" is valid British English, but the directory
    # was renamed to "license" for consistency with the use of American
    # English in the gpl itself (as shown at the top of this file).
    #
    # The old directory, if still present, can be deleted.

    old_name="licence"
    if [[ -d "./${old_name}" ]]
    then
        rm -f "./${old_name}/gpl.txt"
        rmdir "./${old_name}"
    fi

    # Obsolete files in Linux download scripts, version 1.19.1-ESR
    #
    # Version 1.19.1-ESR of the Linux download scripts was meant for WSUS
    # Offline Update, version 11.9.1 ESR. It disabled all self-updates,
    # because ESR versions at wsusoffline.net could not get any updates
    # for the static download definitions nor upgrade itself to new
    # versions.
    #
    # This was changed in WSUS Offline Update, Community Edition
    # 11.9.1, but the self-update of the Linux download scripts is
    # still disabled. It was introduced in the first beta-versions,
    # but it is considered obsolete by now.

    rm -f ./available-tasks/60-check-script-version.bash

    if [[ -d ./versions ]]
    then
        rm -f ./versions/installed-version.txt
        rm -f ./versions/available-version.txt
        rmdir ./versions
    fi

    if [[ -d ../timestamps ]]
    then
        rm -f ../timestamps/check-sh-version.txt
    fi

    # Obsolete files in Linux download scripts, version 1.19.4-ESR and 2.3
    #
    # The archives of the Sysinternals utilities are now downloaded to
    # the directory ../bin, instead of ../cache
    for filename in "AutoLogon.zip" "Sigcheck.zip" "Streams.zip"
    do
        if [[ -f "${cache_dir}/${filename}" ]]
        then
            if [[ -f "../bin/${filename}" ]]
            then
                rm "${cache_dir}/${filename}"
            else
                mkdir -p "../bin"
                mv "${cache_dir}/${filename}" "../bin"
            fi
        fi
    done

    # The script 30-remove-default-languages.bash was replaced with the
    # function filter_default_languages in the library dos-files.bash.
    file_list+=(
        "./download-updates-tasks/30-remove-default-languages.bash"
    )

    # Obsolete files in Linux download scripts, version 1.20-ESR and 2.4
    #
    # The private file ./libraries/locales.txt is no longer needed,
    # because the file ../exclude/ExcludeList-locales.txt can be used
    # instead.
    file_list+=( "./libraries/locales.txt" )

    # Delete all obsolete files, if existing
    if (( "${#file_list[@]}" > 0 ))
    then
        for pathname in "${file_list[@]}"
        do
            if [[ -f "${pathname}" ]]
            then
                log_debug_message "Deleting ${pathname}"
                rm "${pathname}"
            fi
        done
    fi

    # The format of the hashdeep files was changed in WSUS Offline Update,
    # Community Editions 11.9.8-ESR and 12.5. The relative path mode
    # option (-l) was replaced with the bare mode option (-b). Hashdeep
    # files in the old format must be removed once, because they would
    # cause every update to be reported as "moved".
    #
    # Reset the array file_list to list only the hashdeep files
    shopt -s nullglob
    file_list=( ../client/md/hashes-*.txt )
    shopt -u nullglob

    if (( "${#file_list[@]}" > 0 ))
    then
        for pathname in "${file_list[@]}"
        do
            filename="${pathname##*/}"
            if grep -F -q -e "-c md5,sha1,sha256 -b" \
                          -e "-c sha1 -b"            \
                             "${pathname}"
            then
                log_debug_message "Hashdeep file ${filename} is already in new format"
            else
                log_info_message "Deleting old style hashdeep file ${filename}"
                rm "${pathname}"
            fi
        done
    fi

    return 0
}

# ========== Commands =====================================================

remove_obsolete_scripts
return 0
