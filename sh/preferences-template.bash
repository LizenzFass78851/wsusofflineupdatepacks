# This file will be sourced by the shell bash.
#
# Filename: preferences-template.bash
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
#     This file allows to change some options for the download
#     script. The default values of these options are defined in the
#     scripts download-updates.bash and update-generator.bash, but they
#     should not be edited in these files.
#
#     To make changes, rename the file preferences-template.bash to
#     preferences.bash. This way, the configuration won't be overwritten
#     during updates.


# Set the search order for the supported download utilities.
supported_downloaders="wget aria2c"

# Proxy servers should be entered in the format
#
# [http://][username:password@]server[:port]
#
# If in doubt, refer to the manual pages of wget and aria2c.
#
# Proxy server for unencrypted connections
proxy_server=""
# Proxy server for secure connections (usually the same as above)
secure_proxy_server=""
# A comma-delimited list of domains, which should be connected directly
no_proxy_server=""


# Boolean options
#
# Use "enabled" or "disabled" for the following options.

# Prefer "security-only" updates over the full "quality" update rollups
# for:
# - Windows Server 2012
# - Windows 8.1 / Server 2012 R2
prefer_seconly="disabled"

# All online checks for self updates can be disabled to keep a certain
# installation as is. This may be needed to support old Windows versions
# which are no longer supported by newer versions of WSUS Offline
# Update. Setting the option check_for_self_updates to "disabled"
# prevents the online checks for:
#
# - new versions of WSUS Offline Update
# - new versions of the Linux download scripts
# - updates of the configuration files
check_for_self_updates="enabled"

# By default, new versions of WSUS Offline Update or the Linux download
# scripts are only installed after manual confirmation.
#
# New versions are reported to the user and then the script waits for
# confirmation to install them. This dialog automatically selects "no"
# after 30 seconds, to let the script continue if nobody is watching. This
# also means, that new versions may be missed.
#
# Setting the variable unattended_updates to "enabled" changes this
# behavior: New versions are still reported to the user, but the dialog
# automatically selects "yes" after 30 seconds. This will install all
# updates automatically. This makes the script download-updates.bash
# better suited for automated tasks like cron jobs.
unattended_updates="disabled"


# Verification of digital file signatures
#
# The verification of digital file signature with wine and Sysinternals
# Sigcheck is disabled by default because of compatibility considerations:
#
# - Current versions of Sigcheck don't run on old CPUs of the Pentium
#   III class.
#
# - The check of digital file signatures is still flawed: Without the
#   necessary Microsoft certificates, Sigcheck can not really validate
#   the signatures; it only detects if a signature is present or not.
#
# Sigcheck version 2.0 and 2.1 still support old CPUs like the Pentium
# III and Athlon XP. Older versions of Sigcheck should not be used,
# because they use different command line options.
#
# Sigcheck version 2.2 and later only run on current CPUs with the SSE2
# instruction set.
#
# On Linux, CPU capabilities may be checked by reading the /proc
# directory:
#
# less /proc/cpuinfo
#
# If the "CPU flags" include sse2, Sigcheck 2.2 can be used without
# problems.
#
# As an additional compatibility test, change to the directory
# wsusoffline/bin and run the command:
#
# wine sigcheck.exe sigcheck.exe
#
# Then Sigcheck should display some information about itself. If this
# works, the verification of digital file signatures may be enabled.
use_file_signature_verification="disabled"

# The creation and verification of an own integrity database with hashdeep
# can be skipped to make the script run faster.
use_integrity_database="enabled"

# In the Windows script DownloadUpdates.cmd, hashdeep always uses
# three hash functions to create the integrity database: MD5, SHA-1 and
# SHA-256. This looks a bit over-engineered, and it makes the creation and
# validation of the integrity database rather slow on old machines. The
# Linux download scripts 1.19.4-ESR and 2.3 introduced a new optional
# "fast mode", which only calculates the SHA-1 hash.
fast_mode="disabled"

# The cleanup of client directories can be skipped, if there are
# unexpected problems.
use_cleanup_function="enabled"

# The method to keep "valid static files" during the cleanup of client
# directories was a workaround for the first versions of the Linux
# download scripts, which could only download one update and one language
# per run. If different languages were needed, then the existing files had
# to be kept between download runs. This was solved with a recursive grep
# for the whole static directory: if the downloads were still referenced
# from that directory, they would be considered "valid static files"
# and not deleted.
#
# The internal command "select" of the bash does not allow multiple
# selections either.
#
# With newer versions and the external command "dialog", this works much
# better, and the option to keep existing files may now be disabled.
keep_valid_static_files="enabled"

# Create more output for debugging. This is only meant for development.
debug="disabled"

# The download and installation of security only update rollups for
# Windows 7, 8, 8.1 and the corresponding server versions depends on
# the configuration files:
#
# - wsusoffline/client/exclude/HideList-seconly.txt
# - wsusoffline/client/static/StaticUpdateIds-w61-seconly.txt
# - wsusoffline/client/static/StaticUpdateIds-w62-seconly.txt
# - wsusoffline/client/static/StaticUpdateIds-w63-seconly.txt
#
# These files should be updated after the official patch day, which
# is the second Tuesday each month. This is done by the maintainer
# of WSUS Offline Update, and new configuration files are downloaded
# automatically.
#
# In the meantime, the function seconly_safety_guard compares the
# modification dates of the configuration files to the official patch
# day. The script will exit and postpone the download, if the files are
# not yet updated. This is done to prevent serious side effects.
#
# Otherwise, WSUS Offline Update will default to download and install the
# latest full quality update rollup. Since these updates are cumulative,
# this will likely spoil an installation, which was meant to get security
# only updates instead.
#
# The configuration files can also be updated manually. This is described
# in the forum at:
#
# - https://forums.wsusoffline.net/viewtopic.php?f=4&t=6897&start=10#p23708
#
# If the configuration files have been updated and verified manually, you
# can change the variable exit_on_configuration_problems to "disabled".
exit_on_configuration_problems="enabled"

return 0
