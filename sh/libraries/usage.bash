# This file will be sourced by the shell bash.
#
# Filename: usage.bash
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
#     The usage page is shown, if too less or wrong parameters are
#     entered on the command line.
#
#     Optimally, the usage page should be a short overview, which fits in
#     a 80 x 22 window. Then both the previous and the next command prompt
#     can be seen. This allows an easy correction of the command line.
#
#     The complete documentation is in the file documentation/usage.txt.


function show_usage ()
{
    cat << EOF
USAGE
   ./download-updates.bash UPDATE[,UPDATE...] LANGUAGE[,LANGUAGE...] \
   [OPTIONS]

UPDATE
    w60           Windows Server 2008, 32-bit
    w60-x64       Windows Server 2008, 64-bit
    w61           Windows 7, 32-bit
    w61-x64       Windows 7 / Server 2008 R2, 64-bit
    w62-x64       Windows Server 2012, 64-bit              (deprecated)
    w63           Windows 8.1, 32-bit                      (deprecated)
    w63-x64       Windows 8.1 / Server 2012 R2, 64-bit     (deprecated)
    w100          Windows 10, 32-bit                       (deprecated)
    w100-x64      Windows 10 / Server 2016/2019, 64-bit    (deprecated)
    o2k13         Office 2013, 32-bit                      (deprecated)
    o2k13-x64     Office 2013, 32-bit and 64-bit           (deprecated)
    o2k16         Office 2016, 32-bit                      (deprecated)
    o2k16-x64     Office 2016, 32-bit and 64-bit           (deprecated)
    all           All Windows and Office updt., 32/64-bit  (deprecated)
    all-x86       All Windows and Office updates, 32-bit   (deprecated)
    all-x64       All Windows and Office updates, 64-bit   (deprecated)
    all-win       All Windows updates, 32-bit and 64-bit   (deprecated)
    all-win-x86   All Windows updates, 32-bit              (deprecated)
    all-win-x64   All Windows updates, 64-bit              (deprecated)
    all-ofc       All Office updates, 32-bit and 64-bit    (deprecated)
    all-ofc-x86   All Office updates, 32-bit               (deprecated)

    Notes: Multiple updates can be joined to a comma-separated list like
    "w63,w63-x64".

LANGUAGE
    deu    German
    enu    English
    ara    Arabic
    chs    Chinese (Simplified)
    cht    Chinese (Traditional)
    csy    Czech
    dan    Danish
    nld    Dutch
    fin    Finnish
    fra    French
    ell    Greek
    heb    Hebrew
    hun    Hungarian
    ita    Italian
    jpn    Japanese
    kor    Korean
    nor    Norwegian
    plk    Polish
    ptg    Portuguese
    ptb    Portuguese (Brazil)
    rus    Russian
    esn    Spanish
    sve    Swedish
    trk    Turkish

    Note: Multiple languages can be joined to a comma-separated list like
    "deu,enu".

OPTIONS
   -includesp
        Include Service Packs

   -includecpp
        Include Visual C++ runtime libraries

   -includedotnet
        Include .NET Frameworks: localized installation files and updates

   -includewddefs
        Windows Defender definition updates for the built-in Defender
        of Windows Vista and 7

   -includemsse
        Microsoft Security Essentials: localized installation files and
        virus definition updates. Microsoft Security Essentials is an
        optional installation for Windows Vista and 7.

   -includewddefs8
        Windows Defender definition updates for the built-in Defender
        of Windows 8, 8.1 and 10

        These are the same virus definition updates as for Microsoft
        Security Essentials, and they are downloaded to the same
        directories, but without the localized installers.

        Therefore, "wddefs8" is a subset of "msse", and you should use
        -includemsse instead for the internal lists "all" and "all-win".
EOF
}

return 0
