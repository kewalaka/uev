<#
    .SYNOPSIS
        AppVeyor tests setup script.
#>
# AppVeyor Testing
If (Test-Path 'env:APPVEYOR_BUILD_FOLDER') {
    $projectRoot = $env:APPVEYOR_BUILD_FOLDER
}
Else {
    # Local Testing 
    $projectRoot = ((Get-Item (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)).Parent).FullName
}

$res = Invoke-Pester -Path "$projectRoot\tests" -OutputFormat NUnitXml -OutputFile TestsResults.xml -PassThru
(New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path .\TestsResults.xml))
If ($res.FailedCount -gt 0) { Throw "$($res.FailedCount) tests failed." }

# Line break for readability in AppVeyor console
Write-Host -Object ''
