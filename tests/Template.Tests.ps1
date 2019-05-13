# AppVeyor Testing
If (Test-Path 'env:APPVEYOR_BUILD_FOLDER') {
    $projectRoot = $env:APPVEYOR_BUILD_FOLDER
}
Else {
    # Local Testing 
    $projectRoot = ((Get-Item (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)).Parent).FullName
}

#region Tests
$path = Join-Path $projectRoot "templates"
$templates = Get-ChildItem -Path $path -Recurse -Include *.*

Describe "Template format tests" {
    ForEach ($template in $templates) {
        It "$($template.Name) should be an .XML file" {
            [IO.Path]::GetExtension($template.Name) -match ".xml" | Should -Be $True
        }
        It "$($template.Name) should be in XML format" {
            Try {
                [xml] $content = Get-Content -Path $template.FullName -Raw -ErrorAction SilentlyContinue
            }
            Catch {
                Write-Warning "Failed to read $($template.Name)."
            }
            $content | Should -BeOfType System.Xml.XmlNode
        }
    }
}
#endregion
