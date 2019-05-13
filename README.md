# User Experience Virtualization templates

[![License][license-badge]][license]
[![Build status][appveyor-badge]][appveyor-build]

A set of custom User Experience Virtualization templates pushed to blog storage on an Azure storage account. Used with Windows 10 Enterprise PCs managed via Microsoft Intune (or other MDM).

Deploy the PowerShell script [`Set-Uev.ps1`](https://github.com/aaronparker/Intune-Scripts/tree/master/Uev) to target PCs to enable the UE-V service, download the templates from the storage account and register them locally.

[appveyor-badge]: https://img.shields.io/appveyor/ci/aaronparker/uev/master.svg?style=flat-square&logo=appveyor
[appveyor-build]: https://ci.appveyor.com/project/aaronparker/uev
[license-badge]: https://img.shields.io/github/license/aaronparker/uev.svg?style=flat-square
[license]: https://github.com/aaronparker/vcredist/blob/master/LICENSE
