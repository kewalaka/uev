<#
    .SYNOPSIS
        AppVeyor pre-deploy script.
#>
# AppVeyor Testing
If (Test-Path 'env:APPVEYOR_BUILD_FOLDER') {
    $projectRoot = $env:APPVEYOR_BUILD_FOLDER
}
Else {
    # Local Testing 
    $projectRoot = ((Get-Item (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)).Parent).FullName
}

# Line break for readability in AppVeyor console
Write-Host -Object ''

# Make sure we're using the Master branch and that it's not a pull request
# Environmental Variables Guide: https://www.appveyor.com/docs/environment-variables/
If ($env:APPVEYOR_REPO_BRANCH -ne 'master') {
    Write-Warning -Message "Skipping version increment and push for branch $env:APPVEYOR_REPO_BRANCH"
}
ElseIf ($env:APPVEYOR_PULL_REQUEST_NUMBER -gt 0) {
    Write-Warning -Message "Skipping version increment and push for pull request #$env:APPVEYOR_PULL_REQUEST_NUMBER"
}
Else {

    # Tests success, push to GitHub
    If ($res.FailedCount -eq 0) {
        # Publish the new version back to Master on GitHub
        Try {
            # Set up a path to the git.exe cmd, import posh-git to give us control over git
            $env:Path += ";$env:ProgramFiles\Git\cmd"
            # Import-Module posh-git -ErrorAction Stop

            # Configure the git environment
            git config --global credential.helper store
            Write-Host "Key: $env:GitHubKey" -ForegroundColor Cyan
            Add-Content "$env:USERPROFILE\.git-credentials" "https://$($env:GitHubKey):x-oauth-basic@github.com`n"
            git config --global user.email "$env:APPVEYOR_REPO_COMMIT_AUTHOR_EMAIL"
            git config --global user.name "$env:APPVEYOR_REPO_COMMIT_AUTHOR"
            git config --global core.autocrlf true
            git config --global core.safecrlf false

            # Push changes to GitHub
            git checkout master
            git add --all
            git status
            git commit -s -m "AppVeyor validate: $env:APPVEYOR_BUILD_VERSION"
            git push origin master
            Write-Host "$env:APPVEYOR_BUILD_VERSION pushed to GitHub." -ForegroundColor Cyan
        }
        Catch {
            # Sad panda; it broke
            Write-Warning "Push to GitHub failed."
            Throw $_
        }
    }
}
