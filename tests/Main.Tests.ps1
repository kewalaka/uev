# AppVeyor Testing
If (Test-Path 'env:APPVEYOR_BUILD_FOLDER') {
    $projectRoot = $env:APPVEYOR_BUILD_FOLDER
}
Else {
    # Local Testing 
    $projectRoot = ((Get-Item (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)).Parent).FullName
}
