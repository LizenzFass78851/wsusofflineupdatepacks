# WSUSOffline Update Packs
This repository contains wsusoffline package (Windows Update Pack) for supported Windows and Office versions

> [!IMPORTANT]
> **no guarantee that the packages are up-to-date and functional**
> (there is no influence on some things)

See the [releases](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases) to download the releases

## Latest Update Packs
| Product | Link |
|:------------------:|:--------------:|
| Windows Server 2012 (x64) | [w62-x64](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/latest-w62-x64) |
| Windows 8.1 (x86) | [w63](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/latest-w63) |
| Windows 8.1 / Windows Server 2012 R2 (x64) | [w63-x64](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/latest-w63-x64) |
| Windows 10 (x86) | [w100](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/latest-w100) |
| Windows 10 / Windows Server 2016/2019 (x64) | [w100-x64](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/latest-w100-x64) |
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
| Windows 10 (x86) | [w100](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/esr-w100) |
| Windows 10 / Windows Server 2016/2019 (x64) | [w100-x64](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/esr-w100-x64) |
| Office 2013 (x86/x64) | [o2k13](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/esr-o2k13) |
| Office 2016 (x86/x64) | [o2k16](https://github.com/LizenzFass78851/wsusofflineupdatepacks/releases/tag/esr-o2k16) |

### Build state: 
[![generate_products](https://github.com/LizenzFass78851/wsusofflineupdatepacks/actions/workflows/generate_products.yml/badge.svg?branch=main)](https://github.com/LizenzFass78851/wsusofflineupdatepacks/actions/workflows/generate_products.yml)

> [!NOTE]
> - The ISOs published there are split into 1.9 GB files each.
>   - Put these back together under Linux using the cut command.
>   - On Windows this is possible with 7zip.
> - To install Windows updates via the wsusoffline package, the antivirus program must be deactivated. **it is false positive**
> - This automation uses the source code from akar@wsusoffline on [gitlab](https://gitlab.com/wsusoffline/wsusoffline) and this repository contains the already compiled program files for wsusoffline so that the automation can provide these packages for the above-mentioned systems
