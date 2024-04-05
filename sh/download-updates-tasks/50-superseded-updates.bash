# This file will be sourced by the shell bash.
#
# Filename: 50-superseded-updates.bash
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
#     This task calculates superseded updates. The current implementation
#     for both Windows and Linux is depicted in a forum article:
#
#     https://forums.wsusoffline.net/viewtopic.php?f=5&t=5676


# ========== Functions ====================================================

# The WSUS catalog file package.xml is only extracted from the archive
# wsusscn2.cab, if this file changes. Otherwise, a cached copy of
# package.xml is used.

function check_wsus_catalog_file ()
{
    if [[ -f "${cache_dir}/package.xml"           \
       && -f "${cache_dir}/package-formatted.xml" \
       && -f "../client/catalog-creationdate.txt" ]]
    then
        log_info_message "Found cached update catalog file package.xml"
    else
        unpack_wsus_catalog_file
    fi
    return 0
}

function unpack_wsus_catalog_file ()
{
    # Preconditions
    require_file "../client/wsus/wsusscn2.cab" || fail "The required file wsusscn2.cab is missing"

    # Delete existing files, just to be sure
    rm -f "${cache_dir}/package.xml"
    rm -f "${cache_dir}/package-formatted.xml"
    rm -f "../client/catalog-creationdate.txt"

    # Create the cache directory, if it does not exist yet
    mkdir -p "${cache_dir}"

    # cabextract often warns about "possible extra bytes at end of file",
    # if the file wsusscn2.cab is tested or expanded. These warnings
    # can be ignored.

    log_info_message "Extracting Microsoft's update catalog file (ignore any warnings about extra bytes at end of file)..."

    # As of 2019-02-26, cabextract is still broken in Debian 10
    # Buster/testing, although two relevant bug reports have long been
    # closed and marked as "Fixed":
    #
    # - libmspack0: Regression when extracting cabinets using -F option
    #   fixed upstream, needs to be patched
    #   https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=912687
    # - cabextract: -F option doesn't work correctly.
    #   https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=914263
    #
    # cabextract on Debian 10 Buster may create a damaged file package.cab
    # at the first step, but without setting any error code. The file
    # package.cab can only be tested with "cabextract -t", which is used
    # by the function verify_cabinet_file.
    #
    # The workaround is to omit the option -F and extract the file
    # wsusscn2.cab completely.

    log_info_message "Step 1: Extracting package.cab from wsusscn2.cab ..."
    if cabextract -d "${temp_dir}" -F "package.cab" "../client/wsus/wsusscn2.cab" \
       && verify_cabinet_file "${temp_dir}/package.cab"
    then
        log_info_message "The file package.cab was extracted successfully."
    else
        log_warning_message "The extraction of package.cab failed. Trying workaround for broken cabextract in Debian 10 Buster/testing..."
        # The archive wsusscn2.cab must be completely expanded, which
        # may take slightly longer.
        if cabextract -d "${temp_dir}" "../client/wsus/wsusscn2.cab" \
           && verify_cabinet_file "${temp_dir}/package.cab"
        then
            log_info_message "The file package.cab was extracted successfully."
        else
            rm -f "${timestamp_dir}/timestamp-wsus-all-glb.txt"
            fail "The file package.cab could not be extracted. The script cannot continue without this file."
        fi
    fi

    # The option -F was never really needed for the second step, because
    # the archive package.cab only contains one file, package.xml.

    log_info_message "Step 2: Extracting package.xml from package.cab ..."
    if cabextract -d "${cache_dir}" "${temp_dir}/package.cab" \
       && ensure_non_empty_file "${cache_dir}/package.xml"
    then
        log_info_message "The file package.xml was extracted successfully."
    else
        rm -f "${timestamp_dir}/timestamp-wsus-all-glb.txt"
        fail "The file package.xml could not be extracted. The script cannot continue without this file."
    fi

    # Create a formatted copy of the file package.xml
    #
    # The file package.xml contains just one long line without any line
    # breaks. This is the most compact form of XML files and similar
    # formats like JSON. In this form, it can be parsed by applications,
    # but it cannot be displayed in a text editor nor searched with
    # grep. For convenience, the script also creates a pretty-printed
    # copy of the file with the name package-formatted.xml.

    log_info_message "Creating a formatted copy of the file package.xml ..."
    "${xmlstarlet}" format "${cache_dir}/package.xml" > "${cache_dir}/package-formatted.xml"

    # Extract the CreationDate of the file package.xml
    #
    # The CreationDate can be found in the second line of the file
    # package-formatted.xml, for example:
    #
    # <OfflineSyncPackage
    # xmlns="http://schemas.microsoft.com/msus/2004/02/OfflineSync"
    # MinimumClientVersion="5.8.0.2678" ProtocolVersion="1.0"
    # PackageId="ec984487-b493-4c3a-bc8f-b27119c4e4aa"
    # SourceId="cc56dcba-9026-4399-8535-7a3c9bed7086"
    # CreationDate="2019-04-06T03:56:57Z" PackageVersion="1.1">
    #
    # The date can be extracted with sed, but if the search pattern
    # cannot be found, then sed will return the whole input line. To
    # prevent this result, the XML attributes are split into single lines,
    # and the correct one is selected with grep.
    #
    # It is also possible, to use another XSLT transformation for the
    # extraction of this attribute, but this will take much longer.
    #
    # See also: https://forums.wsusoffline.net/viewtopic.php?f=3&t=8997

    # TODO: This always looked like a hack. Using an XSLT file may take
    # longer, but it is only needed once per month.

    if [[ -f "../cache/package-formatted.xml" ]]
    then
        log_info_message "Extracting the catalog CreationDate..."

        head -n 2 "../cache/package-formatted.xml"                  \
            | tail -n 1                                             \
            | tr ' ' '\n'                                           \
            | grep -F "CreationDate"                                \
            | sed 's/^CreationDate="\([[:print:]]\{20\}\)".*$/\1/'  \
            | unix_to_dos                                           \
            > "../client/catalog-creationdate.txt"                  \
            || true

        get_catalog_creationdate
    else
        log_warning_message "The file package-formatted.xml was not found."
    fi

    return 0
}


# The files ExcludeList-Linux-superseded.txt and
# ExcludeList-Linux-superseded-seconly.txt will be deleted, if a new
# version of WSUS Offline Update or the Linux download scripts is
# installed, or if any of the following configurations files has changed:
#
# ../exclude/ExcludeList-superseded-exclude.txt
# ../exclude/ExcludeList-superseded-exclude-seconly.txt
# ../client/exclude/HideList-seconly.txt
# ../client/wsus/wsusscn2.cab
#
# The function check_superseded_updates then checks, if the exclude
# lists still exist.
#
# Previously, this function did some more checks, but since the files
# ExcludeList-superseded.txt and ExcludeList-superseded-seconly.txt were
# renamed in version 1.5 of the Linux download scripts, these tests are
# not needed anymore.
#
# For example, the ExcludeList-superseded.txt originally contained only
# the filenames, not the complete URLs. To make sure, that the new format
# was used, the script would search for "http://".

function check_superseded_updates ()
{
    if [[ -f "../exclude/ExcludeList-Linux-superseded.txt" \
       && -f "../exclude/ExcludeList-Linux-superseded-seconly.txt" ]]
    then
        log_info_message "Found valid list of superseded updates"
    else
        rebuild_superseded_updates
    fi
    return 0
}


# The function rebuild_superseded_updates calculates two alternate lists
# of superseded updates:
#
# ../exclude/ExcludeList-Linux-superseded.txt
# ../exclude/ExcludeList-Linux-superseded-seconly.txt

function rebuild_superseded_updates ()
{
    local -a excludelist_overrides=()
    local -a excludelist_overrides_seconly=()
    local current_file=""
    local kb_number=""

    # Delete existing files, just to be sure
    rm -f "../exclude/ExcludeList-Linux-superseded.txt"
    rm -f "../exclude/ExcludeList-Linux-superseded-seconly.txt"

    log_info_message "Determining superseded updates..."

    # *** Step 0: Files used multiple times ***

    # The file revision-and-update-ids.txt is a complete list of bundle
    # revision ids and update ids for all products
    log_info_message "Extracting revision-and-update-ids.txt..."
    xml_transform "extract-revision-and-update-ids.xsl" \
                          "revision-and-update-ids.txt"

    # The function xml_transform sorts the result by the whole line.
    #
    # For the re-implementation of the revised method for the calculation
    # of superseded updates, the file revision-and-update-ids.txt must
    # also be sorted by the second field. In this case, the option
    # --unique (-u) should be used with caution. It seems to be safe,
    # if the order of all fields is explicitly specified. Otherwise,
    # uniq can be used to remove duplicate lines.
    sort -t ',' -k '2,2' -k '1,1'                 \
        "${temp_dir}/revision-and-update-ids.txt" \
      > "${temp_dir}/revision-and-update-ids-inverted-unclean.txt"

    uniq                                                           \
        "${temp_dir}/revision-and-update-ids-inverted-unclean.txt" \
      > "${temp_dir}/revision-and-update-ids-inverted.txt"

    log_info_message "Extracting BundledUpdateRevisionAndFileIds.txt..."
    xml_transform "extract-update-revision-and-file-ids.xsl" \
                  "BundledUpdateRevisionAndFileIds.txt"

    log_info_message "Extracting UpdateCabExeIdsAndLocations.txt..."
    xml_transform "extract-update-cab-exe-ids-and-locations.xsl" \
                  "UpdateCabExeIdsAndLocations.txt"

    log_info_message "Extracting existing-bundle-revision-ids.txt..."
    xml_transform "extract-existing-bundle-revision-ids.xsl" \
                          "existing-bundle-revision-ids.txt"

    # *** Step 1: Extract RevisionIds from HideList-seconly.txt
    #             [target: revision-ids-HideList-seconly.txt] ***

    if [[ -f "../client/exclude/HideList-seconly.txt" ]]
    then
        log_info_message "Creating file-and-update-ids.txt..."
        join -t "," -e "unavailable" -o "2.3,1.2"             \
            "${temp_dir}/revision-and-update-ids.txt"         \
            "${temp_dir}/BundledUpdateRevisionAndFileIds.txt" \
          > "${temp_dir}/file-and-update-ids.txt"
        sort_in_place "${temp_dir}/file-and-update-ids.txt"

        log_info_message "Creating update-ids-and-locations.txt..."
        join -t "," -e "unavailable" -o "1.2,2.2"         \
            "${temp_dir}/file-and-update-ids.txt"         \
            "${temp_dir}/UpdateCabExeIdsAndLocations.txt" \
          > "${temp_dir}/update-ids-and-locations.txt"
        sort_in_place "${temp_dir}/update-ids-and-locations.txt"

        log_info_message "Creating UpdateTable-all.csv..."
        extract_ids_and_filenames                      \
            "${temp_dir}/update-ids-and-locations.txt" \
            "${temp_dir}/UpdateTable-all.csv"
        sort_in_place "${temp_dir}/UpdateTable-all.csv"

        log_info_message "Extracting HideList-seconly-KBNumbers.txt..."
        cut -d ',' -f '1'                            \
            "../client/exclude/HideList-seconly.txt" \
          > "${temp_dir}/HideList-seconly-KBNumbers.txt"

        log_info_message "Creating UpdateTable-HideList-seconly.csv..."
        grep -F -i -f                                      \
            "${temp_dir}/HideList-seconly-KBNumbers.txt"   \
            "${temp_dir}/UpdateTable-all.csv"              \
          > "${temp_dir}/UpdateTable-HideList-seconly.csv" \
            || true

        log_info_message "Creating update-ids-HideList-seconly.txt..."
        cut -d ',' -f '1'                                  \
            "${temp_dir}/UpdateTable-HideList-seconly.csv" \
          > "${temp_dir}/update-ids-HideList-seconly.txt"
        sort_in_place "${temp_dir}/update-ids-HideList-seconly.txt"

        log_info_message "Creating revision-ids-HideList-seconly.txt..."
        join -t "," -e "unavailable" -1 "2" -o "1.1"           \
            "${temp_dir}/revision-and-update-ids-inverted.txt" \
            "${temp_dir}/update-ids-HideList-seconly.txt"      \
          > "${temp_dir}/revision-ids-HideList-seconly.txt"
        sort_in_place "${temp_dir}/revision-ids-HideList-seconly.txt"
        # in DownloadUpdates.cmd: Label :SkipHideList
    else
        log_warning_message "The file ..client/exclude/HideList-seconly.txt was not found"
        log_info_message "Creating blank revision-ids-HideList-seconly.txt..."
        true > "${temp_dir}/revision-ids-HideList-seconly.txt"
        # in DownloadUpdates.cmd: goto SkipHideList
    fi

    # *** Step 2: Calculate the relations of the updates
    #             [target: ValidSupersededRevisionIds(-seconly).txt &
    #                      ValidNonSupersededRevisionIds(-seconly).txt] ***

    log_info_message "Extracting superseding-and-superseded-revision-ids.txt..."
    xml_transform "extract-superseding-and-superseded-revision-ids.xsl" \
                          "superseding-and-superseded-revision-ids.txt"
    sort_in_place "${temp_dir}/superseding-and-superseded-revision-ids.txt"

    log_info_message "Joining superseding-and-superseded-revision-ids.txt and revision-ids-HideList-seconly.txt to superseding-and-superseded-revision-ids-Rollups.txt..."
    # The options -1 "1" -2 "1" should be the default for join
    join -1 "1" -2 "1" -t "," -e "unavailable" -o "1.1,1.2"       \
        "${temp_dir}/superseding-and-superseded-revision-ids.txt" \
        "${temp_dir}/revision-ids-HideList-seconly.txt"           \
      > "${temp_dir}/superseding-and-superseded-revision-ids-Rollups.txt"
    sort_in_place "${temp_dir}/superseding-and-superseded-revision-ids-Rollups.txt"

    log_info_message "Creating superseding-and-superseded-revision-ids-seconly.txt..."
    # "findstr.exe /L /I /V /G:" can be translated to "grep -F -i -v -f"
    grep -F -i -v -f                                                      \
        "${temp_dir}/superseding-and-superseded-revision-ids-Rollups.txt" \
        "${temp_dir}/superseding-and-superseded-revision-ids.txt"         \
      > "${temp_dir}/superseding-and-superseded-revision-ids-seconly.txt" \
        || true
    sort_in_place "${temp_dir}/superseding-and-superseded-revision-ids-seconly.txt"

    log_info_message "echo Joining existing-bundle-revision-ids.txt and superseding-and-superseded-revision-ids(-seconly).txt to ValidSupersededRevisionIds(-seconly).txt..."

    join -t "," -e "unavailable" -o "2.2"                         \
        "${temp_dir}/existing-bundle-revision-ids.txt"            \
        "${temp_dir}/superseding-and-superseded-revision-ids.txt" \
      > "${temp_dir}/ValidSupersededRevisionIds.txt"
    sort_in_place "${temp_dir}/ValidSupersededRevisionIds.txt"

    join -t "," -e "unavailable" -o "2.2"                                 \
        "${temp_dir}/existing-bundle-revision-ids.txt"                    \
        "${temp_dir}/superseding-and-superseded-revision-ids-seconly.txt" \
      > "${temp_dir}/ValidSupersededRevisionIds-seconly.txt"
    sort_in_place "${temp_dir}/ValidSupersededRevisionIds-seconly.txt"

    log_info_message "Creating ValidNonSupersededRevisionIds(-seconly).txt..."

    # "grep -F -i -v -f" is a translation of "findstr.exe /L /I /V /G:",
    # but grep always causes troubles:
    # - grep writes an empty output file, if the filter file contains
    #   empty lines. This can be prevented by adding the option -e
    #   "unavailable" to join.
    # - if grep doesn't find any results, then it returns an error code,
    #   which must be masked.
    # - grep can get rather slow for comparing large files.
    # - join works better for large files, because it reads alternately
    #   through two sorted files.
    #
    # grep -F -i -v -f can be replaced with a left join (join -v1) or
    # right join (join -v2), if the input files are compatible and sorted.
    #
    # join -v2 does a "right join"; it will print only lines, which are
    # unique on the right side (in the second file).
    #
    # If both input files are sorted and unique, then the output file
    # must be sorted, too.

    join -v2                                            \
        "${temp_dir}/ValidSupersededRevisionIds.txt"    \
        "${temp_dir}/existing-bundle-revision-ids.txt"  \
      > "${temp_dir}/ValidNonSupersededRevisionIds.txt"

    join -v2                                                    \
        "${temp_dir}/ValidSupersededRevisionIds-seconly.txt"    \
        "${temp_dir}/existing-bundle-revision-ids.txt"          \
      > "${temp_dir}/ValidNonSupersededRevisionIds-seconly.txt"

    # *** Step 3: Get the FileIds for the RevisionIds
    #             [target: OnlySupersededFileIds(-seconly).txt] ***

    log_info_message "Joining ValidSupersededRevisionIds(-seconly).txt and BundledUpdateRevisionAndFileIds.txt to SupersededFileIds(-seconly).txt..."

    join -t "," -e "unavailable" -o "2.3"                 \
        "${temp_dir}/ValidSupersededRevisionIds.txt"      \
        "${temp_dir}/BundledUpdateRevisionAndFileIds.txt" \
      > "${temp_dir}/SupersededFileIds.txt"
    sort_in_place "${temp_dir}/SupersededFileIds.txt"

    join -t "," -e "unavailable" -o "2.3"                    \
        "${temp_dir}/ValidSupersededRevisionIds-seconly.txt" \
        "${temp_dir}/BundledUpdateRevisionAndFileIds.txt"    \
      > "${temp_dir}/SupersededFileIds-seconly.txt"
    sort_in_place "${temp_dir}/SupersededFileIds-seconly.txt"

    log_info_message "Joining ValidNonSupersededRevisionIds(-seconly).txt and BundledUpdateRevisionAndFileIds.txt to NonSupersededFileIds(-seconly).txt..."

    join -t "," -e "unavailable" -o "2.3"                 \
        "${temp_dir}/ValidNonSupersededRevisionIds.txt"   \
        "${temp_dir}/BundledUpdateRevisionAndFileIds.txt" \
      > "${temp_dir}/NonSupersededFileIds.txt"
    sort_in_place "${temp_dir}/NonSupersededFileIds.txt"

    join -t "," -e "unavailable" -o "2.3"                       \
        "${temp_dir}/ValidNonSupersededRevisionIds-seconly.txt" \
        "${temp_dir}/BundledUpdateRevisionAndFileIds.txt"       \
      > "${temp_dir}/NonSupersededFileIds-seconly.txt"
    sort_in_place "${temp_dir}/NonSupersededFileIds-seconly.txt"

    log_info_message "Creating OnlySupersededFileIds(-seconly).txt..."

    join -v2                                   \
        "${temp_dir}/NonSupersededFileIds.txt" \
        "${temp_dir}/SupersededFileIds.txt"    \
      > "${temp_dir}/OnlySupersededFileIds.txt"

    join -v2                                           \
        "${temp_dir}/NonSupersededFileIds-seconly.txt" \
        "${temp_dir}/SupersededFileIds-seconly.txt"    \
      > "${temp_dir}/OnlySupersededFileIds-seconly.txt"

    # *** Step 4: Get the URLs for the FileIds
    #             [target: ExcludeList-superseded-all(-seconly).txt] ***

    log_info_message "Joining OnlySupersededFileIds(-seconly).txt and UpdateCabExeIdsAndLocations.txt to ExcludeList-superseded-all(-seconly).txt..."

    join -t "," -e "unavailable" -o "2.2"             \
        "${temp_dir}/OnlySupersededFileIds.txt"       \
        "${temp_dir}/UpdateCabExeIdsAndLocations.txt" \
      > "${temp_dir}/ExcludeList-superseded-all.txt"
    sort_in_place "${temp_dir}/ExcludeList-superseded-all.txt"

    join -t "," -e "unavailable" -o "2.2"               \
        "${temp_dir}/OnlySupersededFileIds-seconly.txt" \
        "${temp_dir}/UpdateCabExeIdsAndLocations.txt"   \
      > "${temp_dir}/ExcludeList-superseded-all-seconly.txt"
    sort_in_place "${temp_dir}/ExcludeList-superseded-all-seconly.txt"

    # *** Step 5: Apply ExcludeList-superseded-exclude(-seconly).txt
    #            [target: ExcludeList-superseded(-seconly).txt] ***

    # The last step is the removal of superseded updates, which are still
    # needed for the installation. This is done by compiling several
    # "override" files, which typically contain kb numbers only.
    #
    # kb2975061 is defined in the file StaticUpdateIds-w63-upd1.txt,
    # but it seems to be superseded and may be missing
    # during installation. Therefore, the contents of
    # StaticUpdateIds-w63-upd1.txt and StaticUpdateIds-w63-upd2.txt are
    # removed from the lists of superseded updates.
    #
    # The kb numbers are restricted to Windows 8.1.
    cat_existing_files ../client/static/StaticUpdateIds-w63-upd1.txt \
                       ../client/static/StaticUpdateIds-w63-upd2.txt \
    | grep -i -e "^kb"                                               \
    | while IFS=$'\r\n' read -r kb_number
      do
          printf '%s\n' "windows8.1-${kb_number}"
      done > "${temp_dir}/w63-kb-numbers.txt"

    # List of override files for ExcludeList-superseded.txt
    excludelist_overrides+=(
        ../exclude/ExcludeList-superseded-exclude.txt
        ../exclude/custom/ExcludeList-superseded-exclude.txt
        "${temp_dir}/w63-kb-numbers.txt"
    )

    # List of override files for ExcludeList-superseded-seconly.txt
    #
    # TODO: The files StaticUpdateIds-w60*-seconly.txt could also be
    # added to the overrides list, because Windows Server 2008 now uses
    # the same distinction in update rollups and security-only updates
    # as Windows 7, 8 and 8.1.
    #
    # Most probably though, this won't make any difference, because
    # adding the files StaticUpdateIds-w6*-seconly.txt here is based on
    # the wrong assumption, that update rollups supersede security-only
    # updates of the same month. This is, how update rollups were first
    # introduced, but it was changed after just one month:
    #
    # "UPDATED 12/5/2016: Starting in December 2016, monthly rollups
    # will not supersede security only updates. The November 2016 monthly
    # rollup will also be updated to not supersede security only updates."
    # -- https://techcommunity.microsoft.com/t5/windows-blog-archive/more-on-windows-7-and-windows-8-1-servicing-changes/ba-p/166783

    shopt -s nullglob
    excludelist_overrides_seconly+=(
        ../exclude/ExcludeList-superseded-exclude.txt
        ../exclude/ExcludeList-superseded-exclude-seconly.txt
        ../exclude/custom/ExcludeList-superseded-exclude.txt
        ../exclude/custom/ExcludeList-superseded-exclude-seconly.txt
        ../client/static/StaticUpdateIds-w62*-seconly.txt
        ../client/static/StaticUpdateIds-w63*-seconly.txt
        ../client/static/custom/StaticUpdateIds-w62*-seconly.txt
        ../client/static/custom/StaticUpdateIds-w63*-seconly.txt
        "${temp_dir}/w63-kb-numbers.txt"
    )
    shopt -u nullglob

    # The Linux download scripts, version 1.5 and later
    # create the files ExcludeList-Linux-superseded.txt and
    # ExcludeList-Linux-superseded-seconly.txt, because the sort
    # order is not exactly the same as in Windows: The Linux download
    # scripts use a C-style sort by the byte order. The Windows script
    # DownloadUpdates.cmd uses the default sort order of GNU sort,
    # which usually implies a "natural" number sort. This is, of course,
    # a bad idea, because it means, that all URLs are broken down into
    # small pieces, and then the pieces are compared to each other.

    apply_exclude_lists                                   \
        "${temp_dir}/ExcludeList-superseded-all.txt"      \
        "../exclude/ExcludeList-Linux-superseded.txt"     \
        "${temp_dir}/ExcludeList-superseded-exclude.txt"  \
        "${excludelist_overrides[@]}"
    sort_in_place "../exclude/ExcludeList-Linux-superseded.txt"

    apply_exclude_lists                                           \
        "${temp_dir}/ExcludeList-superseded-all-seconly.txt"      \
        "../exclude/ExcludeList-Linux-superseded-seconly.txt"     \
        "${temp_dir}/ExcludeList-superseded-exclude-seconly.txt"  \
        "${excludelist_overrides_seconly[@]}"
    sort_in_place "../exclude/ExcludeList-Linux-superseded-seconly.txt"

    # ========== Post-processing ==========================================

    # After recalculating superseded updates, all dynamic updates must
    # be recalculated as well.
    reevaluate_dynamic_updates

    # Check, that both files were created
    for current_file in "../exclude/ExcludeList-Linux-superseded.txt" \
                        "../exclude/ExcludeList-Linux-superseded-seconly.txt"
    do
        if ensure_non_empty_file "${current_file}"
        then
            log_info_message "Created file ${current_file}"
        else
            fail "File ${current_file} was not created"
        fi
    done

    log_info_message "Determined superseded updates"
    return 0
}

# ========== Commands =====================================================

check_wsus_catalog_file
check_superseded_updates
echo ""
return 0
