<#
    .SYNOPSIS
        AppVeyor install script.
#>
# AppVeyor Testing
If (Test-Path 'env:APPVEYOR_BUILD_FOLDER') {
    $projectRoot = Resolve-Path -Path $env:APPVEYOR_BUILD_FOLDER
}
Else {
    # Local Testing 
    $projectRoot = Resolve-Path -Path (((Get-Item (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)).Parent).FullName)
}

# Line break for readability in AppVeyor console
Write-Host -Object ''
Write-Host "PowerShell Version:" $PSVersionTable.PSVersion.tostring()

# Install packages
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name Pester -SkipPublisherCheck -Force
Install-Module -Name PSScriptAnalyzer -SkipPublisherCheck -Force
Install-Module -Name posh-git -Force

# Set variables
$tests = Join-Path -Path $projectRoot -ChildPath "tests"
$schema = Join-Path -Path $tests -ChildPath "SettingsLocationTemplate.xsd"
$output = Join-Path -Path $projectRoot -ChildPath "TestsResults.xml"

# Echo variables
Write-Host -Object ''
Write-Host "ProjectRoot: $projectRoot."
Write-Host "Tests path:  $tests."
Write-Host "Schema path: $schema."
Write-Host "Output path: $output."

# Import XML validation module
Import-Module (Join-Path -Path $tests -ChildPath "Test-XmlSchema.psm1")
