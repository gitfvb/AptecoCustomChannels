﻿################################################
#
# NOTES
#
################################################

<#

#>


################################################
#
# SCRIPT ROOT
#
################################################

# Load scriptpath
if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
    $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
} else {
    $scriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
}

Set-Location -Path $scriptPath


################################################
#
# SETTINGS
#
################################################

# General settings
$functionsSubfolder = "functions"
$settingsFilename = "settings.json"

# Load settings
$settings = Get-Content -Path "$( $scriptPath )\$( $settingsFilename )" -Encoding UTF8 -Raw | ConvertFrom-Json

# Allow only newer security protocols
# hints: https://www.frankysweb.de/powershell-es-konnte-kein-geschuetzter-ssltls-kanal-erstellt-werden/
if ( $settings.changeTLS ) {
    $AllProtocols = @(    
        [System.Net.SecurityProtocolType]::Tls12
        #[System.Net.SecurityProtocolType]::Tls13,
        ,[System.Net.SecurityProtocolType]::Ssl3
    )
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
}

$logfile = $settings.logfile


################################################
#
# FUNCTIONS AND ASSEMBLIES
#
################################################

Get-ChildItem -Path ".\$( $functionsSubfolder )" | ForEach-Object {
    . $_.FullName
}

Add-Type -AssemblyName System.Security


################################################
#
# LOG INPUT PARAMETERS
#
################################################


"$( [datetime]::Now.ToString("yyyyMMddHHmmss") )`t----------------------------------------------------" >> $logfile
"$( [datetime]::Now.ToString("yyyyMMddHHmmss") )`tCREATE AUTH URL" >> $logfile


################################################
#
# PROCESS
#
################################################

#-----------------------------------------------
# CREATE PAYLOAD
#-----------------------------------------------

$payload = $settings.defaultPayload.PsObject.Copy()
$payload.iat = Get-Unixtime
$payload.exp = ( (Get-Unixtime) + 3600 )


#-----------------------------------------------
# CREATE JWT AND AUTH URI
#-----------------------------------------------

$jwt = Create-JWT -headers $settings.headers -payload $payload -secret ( Get-SecureToPlaintext -String $settings.login.secret )
$authUri = "$( $settings.base )/triggerdialog/sso/auth?jwt=$( $jwt )"
$authUri


#-----------------------------------------------
# OPEN IN DEFAULT BROWSER
#-----------------------------------------------

Start-Process "$( $authUri )"

"$( [datetime]::Now.ToString("yyyyMMddHHmmss") )`tCREATED AUTH URL AND OPENED THE BROWSER" >> $logfile

