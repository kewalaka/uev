<#
    .SYNOPSIS
        Pester tests
#>

# Variables
$path = Join-Path $projectRoot "templates"
$tests = Join-Path $projectRoot "tests"
$schema = Join-Path $tests "SettingsLocationTemplate.xsd"
$templates = Get-ChildItem -Path $path -Recurse -Include *.*

# Export XML validation module
. "$projectRoot\tests\Test-XmlSchema.psm1"

# Echo paths
Write-Host "Templates path: $templates"
Write-Host "Tests path: $tests"

#region Tests
Describe "Template file type tests" {
    ForEach ($template in $templates) {
        It "$($template.Name) should be an .XML file" {
            [IO.Path]::GetExtension($template.Name) -match ".xml" | Should -Be $True
        }
    }
}

Describe "Template XML format tests" {
    ForEach ($template in $templates) {
        It "$($template.Name) should be in XML format" {
            Try {
                [xml] $content = Get-Content -Path $template.FullName -Raw -ErrorAction SilentlyContinue
            }
            Catch {
                Write-Warning "Failed to read $($template.Name)."
            }
            $content | Should -BeOfType System.Xml.XmlNode
        }
        It "$($template.Name) should validate against the schema" {
            Test-XmlSchema -XmlPath $template.FullName -SchemaPath $schema | Should -Be $True
        }
    }
}
#endregion
