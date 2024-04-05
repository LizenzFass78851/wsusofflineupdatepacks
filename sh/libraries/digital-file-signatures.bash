# This file will be sourced by the shell bash.
#
# Filename: digital-file-signatures.bash
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
#     This file implements a function, which uses Sysinternals Sigcheck
#     to validate digital file signatures.
#
#     This does not currently work for several reasons:
#
#     1. The Validation of digital signatures requires the installation
#        of the Microsoft root certificates and complete certificate
#        chains. Without these certificates, Sigcheck will only report,
#        if a file is "signed" or "unsigned".
#
#     2. wine uses a built-in library CRYPT32.dll, which does not
#        provide the necessary functionality to actually verify the
#        signatures. This causes Sigcheck to report many false positive
#        results:
#
#        - If the root certificates or some intermediate certificates are
#          not available, then Sigcheck should return the error message:
#          "A certificate chain could not be built to a trusted root
#          authority". Still, when running under wine, Sigcheck will
#          always report "signed", if there is a signature at all.
#
#        - If a file is slightly modified, for example by appending
#          a space to the end, then this should make the signature
#          invalid. Sigcheck still reports the file as "signed".
#
#     3. The built-in wine library CRYPT32.dll may be replaced with
#        a "native" Windows library with winetricks. But then some
#        other functionality seems to be missing, because every file
#        now returns the general error code -2146885628 (0x80092004),
#        which simply means "Cannot find object or property".
#
#     There are also compatibility issues:
#
#     - Sigcheck 2.2 and later require the CPU instruction set SSE2
#       and won't run on old CPUs like the Pentium III.
#
#     - Sigcheck 2.4 and later require Windows Vista.
#
#     Relevant error codes for Sigcheck can be found in the document
#     "COM Error Codes (Security and Setup)":
#
#     - https://technet.microsoft.com/en-us/sysinternals/dd542646(v=vs.100)
#     - https://msdn.microsoft.com/en-us/windows/desktop/dd542646(v=vs.85)
#
#     CERT_E_EXPIRED
#     0x800B0101
#     A required certificate is not within its validity period when
#     verifying against the current system clock or the timestamp in
#     the signed file.
#
#     CRYPT_E_NOT_FOUND
#     0x80092004
#     Cannot find object or property.
#
#     TODO: In the package wine-development of Debian 8 Jessie,
#     /usr/bin/wine was renamed to /usr/bin/wine-development. Then
#     both names should be checked. In Debian 9 Stretch, the
#     update-alternatives system is used to select the preferred wine
#     version, which is then referenced with a symbolic link "wine".
#
#     TODO: Some updates for the Windows 10, released in April 2017, had
#     expired digital file signatures. This is not really an error. See
#     the discussion in the forum:
#
#     https://forums.wsusoffline.net/viewtopic.php?f=3&t=6540

function verify_digital_file_signatures ()
{
    local download_dir="$1"
    local sigcheck_output=""
    local windows_path=""
    local linux_path=""
    local filename=""
    local file_validation=""
    local skip_rest=""
    local -i initial_errors="0"
    initial_errors="$(get_error_count)"

    # Check preconditions
    if [[ "${use_file_signature_verification}" == "disabled" ]]
    then
        log_info_message "Verification of digital file signatures is disabled in preferences"
        return 0
    fi
    if ! type -P wine > /dev/null
    then
        log_warning_message "Please install the package wine to verify digital file signatures with Sysinternals Sigcheck"
        return 0
    fi
    if [[ ! -f ../bin/"${sigcheck_bin}" ]]
    then
        log_warning_message "Verification of digital file signatures requires Sysinternals Sigcheck"
        return 0
    fi
    if [[ -z "${DISPLAY:-}" ]]
    then
        log_warning_message "The environment variable DISPLAY is not set, either because no X server is running or environment variables are not passed to the script. As a command line application, Sigcheck should still work as expected. wine error messages may be neglected."
    fi
    if ! require_directory "${download_dir}"
    then
        log_error_message "The specified directory ${download_dir} does not exist."
        return 0
    fi

    # Begin processing
    log_info_message "Verifying digital file signatures for directory ${download_dir} ..."
    # Recent versions of Sigcheck use the option -nobanner instead of -q,
    # but there is way to check the file version in Linux. The online
    # documentation for Sigcheck seems to be wrong, since it doesn't
    # mention the new option -nobanner.
    #
    # http://forum.sysinternals.com/sigcheck-online-docu-is-wrong_topic32310.html
    # https://technet.microsoft.com/en-us/sysinternals/bb897441
    #
    # In Windows, the "banner" is written to standard output and can be
    # easily suppressed, but this may not work with wine.
    #
    # With the removal of dotnet subdirectories, the recursive option
    # -s may be used everywhere.
    #
    #local sigcheck_options=( "/accepteula" "-q" "-c" "-s" )             # for Sigcheck 2.0 - 2.4
    local sigcheck_options=(  "/accepteula" "-q" "-c" "-s" "-nobanner" ) # for Sigcheck 2.5 and higher

    # TODO: the error output of sigcheck should not be discarded, but
    # wine itself will also create lots of error messages. This should
    # be sorted out somehow...
    #
    # The result code of sigcheck cannot be tested, because it is masked
    # by wine.
    sigcheck_output="$(wine "../bin/${sigcheck_bin}" "${sigcheck_options[@]}" "${download_dir}" 2> /dev/null | tail -n +2 | unquote)" || true
    log_debug_message "Sigcheck output:" "${sigcheck_output}"

    while IFS=',' read -r windows_path file_validation skip_rest
    do
        if [[ -z "${windows_path}" || -z "${file_validation}" ]]
        then
            fail "Error parsing Sigcheck output"
        fi
        # Using winepath to convert pathnames is better than hard-coding
        # this translation, but it generates unnecessarily long pathnames,
        # including symbolic links in ~/.wine/dosdevices/z:/
        #
        # It also uses wine to convert the file paths, and this is much
        # slower than just translating in the path in the shell.
        #
        # The resulting file path could be further shortened with
        # readlink -f.
        linux_path="$(winepath --unix "${windows_path}")"
        filename="${linux_path##*/}"

        log_debug_message "Windows path: ${windows_path}"
        log_debug_message "Linux path:   ${linux_path}"
        log_debug_message "Filename:     ${filename}"
        log_debug_message "Validation:   ${file_validation}"

        case "${file_validation}" in
            Signed)
                # The file has a digital signature. With the default
                # configuration of wine, Sigcheck can not validate any
                # signatures, since root certificates are not available
                # and a library CRYPT32.dll needs to be replaced. Signed
                # files with wrong digital signatures are still reported
                # as "Signed" on Linux. The only distinction would be
                # between "Signed" and "Unsigned".
                :
            ;;
            Unsigned)
                # Usually, all files from Microsoft should be signed, but
                # this was forgotten for the last version of rootsupd.exe.
                #
                # Furthermore, there are two unsigned zip archives for
                # Windows 7, which need to be excluded from removal.
                #
                # WSUS Offline Update version 11.7.2+ (r1052) added
                # support for *.crt and *.crl files, which are unsigned
                # as well.
                case "${filename}" in
                    "rootsupd.exe" | *.zip | *.crt | *.crl)
                        log_info_message "Kept unsigned file ${filename}"
                    ;;
                    *)
                        increment_error_count
                        log_error_message "Trashing/deleting file ${filename} because it is unsigned..."
                        trash_file "${linux_path}"
                    ;;
                esac
            ;;
            # The following, specific error messages can only be found
            # when running Sigcheck on Windows.
            "Not a cryptographic message or the cryptographic message is not formatted correctly." | \
            "The digital signature of the object did not verify.")
                # The file is signed, but damaged.
                increment_error_count
                log_error_message "Trashing/deleting file ${filename} because the digital file signature could not be verified..."
                trash_file "${linux_path}"
            ;;
            Error*)
                # Error -2146762495 (0x800b0101) means, that the signing
                # date was not in the valid time span of the certificate,
                # e.g. the certificate expired before the file was signed.
                log_warning_message "Received \"${file_validation}\" for file ${filename}"
            ;;
            *)
                # Empty files are "Unsigned", but very small files, with
                # a file length of only 2 bytes, may give the result
                # "Invalid parameter.". This message may be localized
                # as "Ungueltiger Parameter" in German. Of course,
                # the filename does not correspond to any known parameter.
                log_warning_message "Unknown result \"${file_validation}\" for file ${filename}"
            ;;
        esac
    done <<< "${sigcheck_output}"

    if same_error_count "${initial_errors}"
    then
        log_info_message "Verified digital file signatures"
    else
        log_error_message "Verification of digital file signatures detected $(get_error_difference "${initial_errors}") errors"
    fi
    return 0
}

return 0
