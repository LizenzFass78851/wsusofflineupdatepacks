# WSUSOffline Update Packs
This repository contains wsusoffline package (Windows Update Pack) for supported Windows and Office versions

See the [releases](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases) to download the releases

## Latest Update Packs
| Product | Link |
|:------------------:|:--------------:|
| Windows Server 2012 (x64) | [w62-x64](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/latest-w62-x64) |
| Windows 8.1 (x86) | [w63](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/latest-w63) |
| Windows 8.1 / Windows Server 2012 R2 (x64) | [w63-x64](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/latest-w63-x64) |
| Office 2013 (x86/x64) | [o2k13](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/latest-o2k13) |
| Office 2016 (x86/x64) | [o2k16](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/latest-o2k16) |

## ESR Update Packs
| Product | Link |
|:------------------:|:--------------:|
| Windows Server 2008 (x86) | [w60](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/esr-w60) |
| Windows Server 2008 (x64) | [w60-x64](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/esr-w60-x64) |
| Windows 7 (x86) | [w61](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/esr-w61) |
| Windows 7 / Windows Server 2008 R2 (x64) | [w61-x64](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/esr-w61-x64) |
| Windows Server 2012 (x64) | [w62-x64](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/esr-w62-x64) |
| Windows 8.1 (x86) | [w63](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/esr-w63) |
| Windows 8.1 / Windows Server 2012 R2 (x64) | [w63-x64](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/esr-w63-x64) |
| Office 2013 (x86/x64) | [o2k13](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/esr-o2k13) |
| Office 2016 (x86/x64) | [o2k16](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/esr-o2k16) |

### Why are there no update packs available for Windows 10 and newer?
Because from Windows 10 and its server variants it may be easier to get this appropriate cromulative update, which contains all the changes for the corresponding Windows 10 version or newer.
These cromulative updates for Windows 10 and newer can be found under the Microsoft update catalog:
https://www.catalog.update.microsoft.com (example search term: `2023-11 Update for Windows 10 22h2`)

### Build state: 
[![generate_products](https://github.com/LizenzFass78851/wsusofflineupdatepacks/actions/workflows/generate_products.yml/badge.svg?branch=main)](https://github.com/LizenzFass78851/wsusofflineupdatepacks/actions/workflows/generate_products.yml)

> [!NOTE]
> - The ISOs published there are split into 1.9 GB files each.
>   - Put these back together under Linux using the cut command.
>   - On Windows this is possible with 7zip, but the files that follow with .aa .ab and so on can be renamed to .001 .002 and so on.
> - To install Windows updates via the wsusoffline package, the antivirus program must be deactivated. **it is false positive**
> - This automation uses the source code from akar@wsusoffline on [gitlab](https://gitlab.com/wsusoffline/wsusoffline) and this repository contains the already compiled program files for wsusoffline so that the automation can provide these packages for the above-mentioned systems
