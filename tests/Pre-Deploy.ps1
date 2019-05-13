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

Write-Host ""
Write-Host "$env:APPVEYOR"
Write-Host "$env:APPVEYOR_API_URL"
Write-Host "$env:APPVEYOR_ACCOUNT_NAME"
Write-Host "$env:APPVEYOR_PROJECT_ID"
Write-Host "$env:APPVEYOR_PROJECT_NAME"
Write-Host "$env:APPVEYOR_PROJECT_SLUG"
Write-Host "$env:APPVEYOR_BUILD_FOLDER"
Write-Host "$env:APPVEYOR_BUILD_ID"
Write-Host "$env:APPVEYOR_BUILD_NUMBER"
Write-Host "$env:APPVEYOR_BUILD_VERSION"
Write-Host "$env:APPVEYOR_BUILD_WORKER_IMAGE"
Write-Host "$env:APPVEYOR_PULL_REQUEST_NUMBER"
Write-Host "$env:APPVEYOR_PULL_REQUEST_TITLE"
Write-Host "$env:APPVEYOR_PULL_REQUEST_HEAD_REPO_NAME"
Write-Host "$env:APPVEYOR_PULL_REQUEST_HEAD_REPO_BRANCH"
Write-Host "$env:APPVEYOR_PULL_REQUEST_HEAD_COMMIT"
Write-Host "$env:APPVEYOR_JOB_ID"
Write-Host "$env:APPVEYOR_JOB_NAME"
Write-Host "$env:APPVEYOR_JOB_NUMBER"
Write-Host "$env:APPVEYOR_REPO_PROVIDER"
Write-Host "$env:APPVEYOR_REPO_SCM"
Write-Host "$env:APPVEYOR_REPO_NAME"
Write-Host "$env:APPVEYOR_REPO_BRANCH"
Write-Host "$env:APPVEYOR_REPO_TAG"
Write-Host "$env:APPVEYOR_REPO_TAG_NAME"
Write-Host "$env:APPVEYOR_REPO_COMMIT"
Write-Host "$env:APPVEYOR_REPO_COMMIT_AUTHOR"
Write-Host "$env:APPVEYOR_REPO_COMMIT_AUTHOR_EMAIL"
Write-Host "$env:APPVEYOR_REPO_COMMIT_TIMESTAMP"
Write-Host "$env:APPVEYOR_REPO_COMMIT_MESSAGE"
Write-Host "$env:APPVEYOR_REPO_COMMIT_MESSAGE_EXTENDED"
Write-Host "$env:APPVEYOR_SCHEDULED_BUILD"
Write-Host "$env:APPVEYOR_FORCED_BUILD"
Write-Host "$env:APPVEYOR_RE_BUILD"
Write-Host "$env:APPVEYOR_RE_RUN_INCOMPLETE"
Write-Host "$env:PLATFORM"
Write-Host "$env:CONFIGURATION"
Write-Host ""

# Make sure we're using the Master branch and that it's not a pull request
# Environmental Variables Guide: https://www.appveyor.com/docs/environment-variables/
If ($env:APPVEYOR_REPO_BRANCH -ne 'master') {
    Write-Warning -Message "Skipping version increment and publish for branch $env:APPVEYOR_REPO_BRANCH"
}
ElseIf ($env:APPVEYOR_PULL_REQUEST_NUMBER -gt 0) {
    Write-Warning -Message "Skipping version increment and publish for pull request #$env:APPVEYOR_PULL_REQUEST_NUMBER"
}
Else {

    # Tests success, push to GitHub
    If ($res.FailedCount -eq 0) {
        # Publish the new version back to Master on GitHub
        Try {
            # Set up a path to the git.exe cmd, import posh-git to give us control over git, and then push changes to GitHub
            $env:Path += ";$env:ProgramFiles\Git\cmd"
            Import-Module posh-git -ErrorAction Stop
            git checkout master
            git add --all
            git status
            git commit -s -m "AppVeyor validate: $env:APPVEYOR_BUILD_VERSION"
            git push origin master
            Write-Host "$env:APPVEYOR_BUILD_VERSION published to GitHub." -ForegroundColor Cyan
        }
        Catch {
            # Sad panda; it broke
            Write-Warning "Publishing update to GitHub failed."
            Throw $_
        }
    }
}
