Function Test-Xml() {
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string] $SchemaFilePath,

        [Parameter(Mandatory = $false)]
        $Namespace = "http://schemas.microsoft.com/UserExperienceVirtualization/2013A/SettingsLocationTemplate"
    )

    [string[]] $Script:XmlValidationErrorLog = @()
    [scriptblock] $ValidationEventHandler = {
        $Script:XmlValidationErrorLog += "`n" + "Line: $($_.Exception.LineNumber) Offset: $($_.Exception.LinePosition) - $($_.Message)"
    }

    $readerSettings = New-Object -TypeName System.Xml.XmlReaderSettings
    $readerSettings.ValidationType = [System.Xml.ValidationType]::Schema
    $readerSettings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessIdentityConstraints -bor
    [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessSchemaLocation -bor
    [System.Xml.Schema.XmlSchemaValidationFlags]::ReportValidationWarnings
    $readerSettings.Schemas.Add($Namespace, $SchemaFilePath) | Out-Null
    $readerSettings.add_ValidationEventHandler($ValidationEventHandler)

    try {
        $reader = [System.Xml.XmlReader]::Create($Path, $readerSettings)
        while ($reader.Read()) { }
    }

    #handler to ensure we always close the reader since it locks files
    finally {
        $reader.Close()
    }

    if ($Script:XmlValidationErrorLog) {
        [string[]]$ValidationErrors = $Script:XmlValidationErrorLog
        Write-Warning "Xml file ""$Path"" is NOT valid according to schema ""$SchemaFilePath"""
        Write-Warning "$($Script:XmlValidationErrorLog.Count) errors found"
    }
    else {
        Write-Host "Xml file ""$Path"" is valid according to schema ""$SchemaFilePath"""
    }

    Return , $ValidationErrors #The comma prevents powershell from unravelling the collection http://bit.ly/1fcZovr
}
