#Requires -PSEdition Desktop
#Requires -Version 3
#Requires -RunAsAdministrator
<#PSScriptInfo

.VERSION 1.0.0

.GUID c4881872-2b2b-4711-905a-5dae9a19eafd

.AUTHOR Aaron Parker

.COMPANYNAME stealthpuppy

.COPYRIGHT 2019, Aaron Parker. All rights reserved.

.TAGS UE-V Windows10 Profile-Container

.DESCRIPTION Enables and configures the UE-V service on an Intune managed Windows 10 PC

.LICENSEURI https://github.com/aaronparker/Intune-Scripts/blob/master/LICENSE

.PROJECTURI https://github.com/aaronparker/Intune-Scripts/tree/master/Redirections

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
    - May 2019, 1.0.0, Initial version

.PRIVATEDATA
#>
<#
    .SYNOPSIS
        Enables and configures the UE-V service on an Intune managed Windows 10 PC

    .DESCRIPTION
        Enables and configures the UE-V service on a Windows 10 PC. Downloads a set of templates from a target Azure blog storage URI and registers inbox and downloaded templates.

    .PARAMETER Uri
        Specifies the Uniform Resource Identifier (URI) of the Azure blog storage resource that hosts the UE-V templates to download.

    .PARAMETER Templates
        An array of the in-box templates to activate on the UE-V client.

    .NOTES
        Author: Aaron Parker
        Twitter: @stealthpuppy

    .LINK
        https://stealthpuppy.com

    .EXAMPLE
        Set-Uev.ps1
#>
[CmdletBinding(SupportsShouldProcess = $True, HelpURI = "https://github.com/aaronparker/uev/tree/master/")]
[OutputType([String])]
Param (
    [Parameter(Mandatory = $false)]
    [System.String] $Uri = "https://stealthpuppy.blob.core.windows.net/uevtemplates/?comp=list",

    [Parameter(Mandatory = $false)]
    # Inbox templates to enable. Templates downloaded from $Uri will be added to this list
    [System.String[]] $Templates = @("MicrosoftNotepad.xml", "MicrosoftWordpad.xml", "MicrosoftInternetExplorer2013.xml"),

    [Parameter(Mandatory = $false)]
    [System.String] $SettingsStoragePath = "%OneDriveCommercial%"
)

# Configure
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#region Functions
Function Get-AzureBlobItem {
    <#
        .SYNOPSIS
            Returns an array of items and properties from an Azure blog storage URL.

        .DESCRIPTION
            Queries an Azure blog storage URL and returns an array with properties of files in a Container.
            Requires Public access level of anonymous read access to the blob storage container.
            Works with PowerShell Core.
            
        .NOTES
            Author: Aaron Parker
            Twitter: @stealthpuppy

        .PARAMETER Url
            The Azure blob storage container URL. The container must be enabled for anonymous read access.
            The URL must include the List Container request URI. See https://docs.microsoft.com/en-us/rest/api/storageservices/list-containers2 for more information.
        
        .EXAMPLE
            Get-AzureBlobItems -Uri "https://aaronparker.blob.core.windows.net/folder/?comp=list"

            Description:
            Returns the list of files from the supplied URL, with Name, URL, Size and Last Modifed properties for each item.
    #>
    [CmdletBinding(SupportsShouldProcess = $False)]
    [OutputType([System.Management.Automation.PSObject])]
    Param (
        [Parameter(ValueFromPipeline = $True, Mandatory = $True, HelpMessage = "Azure blob storage URL with List Containers request URI '?comp=list'.")]
        [ValidatePattern("^(http|https)://")]
        [System.String] $Uri
    )

    # Get response from Azure blog storage; Convert contents into usable XML, removing extraneous leading characters
    try {
        $iwrParams = @{
            Uri             = $Uri
            UseBasicParsing = $True
            ContentType     = "application/xml"
            ErrorAction     = "Stop"
        }
        $list = Invoke-WebRequest @iwrParams
    }
    catch [System.Net.WebException] {
        Write-Warning -Message ([string]::Format("Error : {0}", $_.Exception.Message))
    }
    catch [System.Exception] {
        Write-Warning -Message "$($MyInvocation.MyCommand): failed to download: $Uri."
        Throw $_.Exception.Message
    }
    If ($Null -ne $list) {
        [System.Xml.XmlDocument] $xml = $list.Content.Substring($list.Content.IndexOf("<?xml", 0))

        # Build an object with file properties to return on the pipeline
        $fileList = New-Object -TypeName System.Collections.ArrayList
        ForEach ($node in (Select-Xml -XPath "//Blobs/Blob" -Xml $xml).Node) {
            $PSObject = [PSCustomObject] @{
                Name         = ($node | Select-Object -ExpandProperty Name)
                Url          = ($node | Select-Object -ExpandProperty Url)
                Size         = ($node | Select-Object -ExpandProperty Size)
                LastModified = ($node | Select-Object -ExpandProperty LastModified)
            }
            $fileList.Add($PSObject) | Out-Null
        }
        If ($Null -ne $fileList) {
            Write-Output -InputObject $fileList
        }
    }
}

Function Test-Windows10Enterprise {
    Try {
        $edition = Get-WindowsEdition -Online -ErrorAction SilentlyContinue
    }
    Catch {
        Write-Error "$($MyInvocation.MyCommand): Failed to run Get-WindowsEdition. Defaulting to False."
    }
    If ($edition.Edition -eq "Enterprise") {
        Write-Output -InputObject $True
    }
    Else {
        Write-Output -InputObject $False
    }
}

Function Get-RandomString {
    -join ((65..90) + (97..122) | Get-Random -Count 8 | ForEach-Object { [char]$_ })
}
#endregion

# If running Windows 10 Enterprise
If (Test-Windows10Enterprise) {

    # If the UEV module is installed, enable the UEV service
    If (Get-Module -ListAvailable -Name UEV) {
        Import-Module -Name UEV

        # Enable the UE-V service
        $status = Get-UevStatus
        If ($status.UevEnabled -ne $True) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Enabling the UE-V service."
            Enable-Uev
            $status = Get-UevStatus
        }
        Else {
            Write-Verbose -Message "$($MyInvocation.MyCommand): UE-V service is enabled."
        }
        If ($status.UevRebootRequired -eq $True) {
            Write-Warning -Message "$($MyInvocation.MyCommand): Reboot required to enable the UE-V service."
        }
    }
    Else {
        Write-Error -Message "$($MyInvocation.MyCommand): UEV module not installed."
    }

    If ($status.UevEnabled -eq $True) {

        # Templates local target path
        $inboxTemplatesSrc = "$env:ProgramData\Microsoft\UEV\InboxTemplates"
        $templatesTemp = Join-Path -Path (Resolve-Path -Path $env:Temp) -ChildPath (Get-RandomString)
        Try {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Creating temp folder: $templatesTemp."
            New-Item -Path $templatesTemp -ItemType Directory -Force | Out-Null
        }
        Catch {
            Write-Warning -Message "$($MyInvocation.MyCommand): Failed to create target: $templatesTemp."
        }

        # Copy the UEV templates from an Azure Storage account
        If (Test-Path -Path $inboxTemplatesSrc) {
    
            # Retrieve the list of templates from the Azure Storage account
            $srcTemplates = Get-AzureBlobItem -Uri $Uri

            # Download each template to the target path and track success
            $downloadedTemplates = New-Object -TypeName System.Collections.ArrayList
            ForEach ($template in $srcTemplates) {

                # Only download if the file has a .xml extension
                If ($template.Name -like "*.xml") {
                    $targetTemplate = Join-Path -Path $templatesTemp -ChildPath $template.Name
                    Try {
                        $iwrParams = @{
                            Uri              = $template.Url
                            OutFile          = $targetTemplate
                            ContentType      = "text/xml"
                            $UseBasicParsing = $True
                            Headers          = @{ "x-ms-version" = "2017-11-09" }
                            ErrorAction      = "SilentlyContinue"
                        }
                        Invoke-WebRequest @iwrParams
                    }
                    catch [System.Net.WebException] {
                        Write-Warning -Message ([string]::Format("Error : {0}", $_.Exception.Message))
                        $failure = $True
                    }
                    catch [System.Exception] {
                        Write-Warning -Message "$($MyInvocation.MyCommand): failed to download: $url."
                        Throw $_.Exception.Message
                        $failure = $True
                    }
                    If ($failure) {
                        Write-Warning -Message "Failed to download $($template.Url)."
                    }
                    Else {
                        $downloadedTemplates.Add($targetTemplate) | Out-Null
                        $Templates.Add($($template.Name)) | Out-Null
                    }
                }
            }

            If ($failure) {
                Write-Warning -Message "Failed on downloading templates."
            }
            Else {
                # Move downloaded templates to the template store
                ForEach ($template in $downloadedTemplates) {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Moving template: $template."
                    Move-Item -Path $template -Destination $inboxTemplatesSrc -Force
                }

                Write-Verbose -Message "$($MyInvocation.MyCommand): Removing temp folder: $templatesTemp."
                Remove-Item -Path $templatesTemp -Recurse -Force

                # Unregister existing templates
                Write-Verbose -Message "$($MyInvocation.MyCommand): Unregistering existing templates."
                Get-UevTemplate | Unregister-UevTemplate -ErrorAction SilentlyContinue

                # Register specified templates
                ForEach ($template in $Templates) {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Registering template: $template."
                    Register-UevTemplate -Path "$inboxTemplatesSrc\$template"
                }

                # Enable Backup mode for all templates
                Get-UevTemplate | ForEach-Object { Set-UevTemplateProfile -Id $_.TemplateId -Profile "Backup" `
                        -ErrorAction "SilentlyContinue" }
            }

            # If the templates registered successfully, configure the client
            If (Get-UevTemplate | Out-Null) {

                # Set the UEV settings. These settings will work for UEV in OneDrive with Enterprise State Roaming enabled
                # https://docs.microsoft.com/en-us/azure/active-directory/devices/enterprise-state-roaming-faqs
                If ($status.UevEnabled -eq $True) {
                    $uevParams = @{
                        Computer                            = $True
                        DisableSyncProviderPing             = $True
                        DisableWaitForSyncOnLogon           = $True
                        DisableSyncUnlistedWindows8Apps     = $True
                        EnableDontSyncWindows8AppSettings   = $True
                        EnableSettingsImportNotify          = $True
                        EnableSync                          = $True
                        EnableWaitForSyncOnApplicationStart = $True
                        SettingsStoragePath                 = $SettingsStoragePath
                        SyncMethod                          = "External"
                        WaitForSyncTimeoutInMilliseconds    = "2000"
                    }
                    Set-UevConfiguration @uevParams
                }
            }
        }
        Else {
            Write-Warning -Message "$($MyInvocation.MyCommand): Path does not exist: $inboxTemplatesSrc."
        }
    }
}
Else {
    Write-Warning -Message "$($MyInvocation.MyCommand): Windows 10 Enterprise is required to enable UE-V."
}
