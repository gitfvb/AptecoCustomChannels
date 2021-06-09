
################################################
#
# SCRIPT ROOT
#
################################################

# Load scriptpath
# MyInvocation is used because it returns the current path of the script
# It is necessary because the path on other computers can differ
if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
    $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
} else {
    $scriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
}

# Current Location will be set as default
Set-Location -Path $scriptPath


################################################
#
# SETTINGS
#
################################################

# General settings
$functionsSubfolder = "functions"
$settingsFilename = "settings.json"


################################################
#
# FUNCTIONS
#
################################################

Get-ChildItem ".\$( $functionsSubfolder )" -Filter "*.ps1" -Recurse | ForEach-Object {
    . $_.FullName
}


################################################
#
# SETTINGS
#
################################################

#-----------------------------------------------
# LOGIN DATA INXMAIL
#-----------------------------------------------

# Entering the username and password
$base = Read-Host "Please enter account name"
$username = Read-Host "Please enter the username for Inxmail"
$password = Read-Host -AsSecureString "Please enter the password for Inxmail"


# Combining username and password; making it ready for BasicAuth
$credentials = "$($username):$(( New-Object PSCredential "dummy",$password).GetNetworkCredential().Password)"

# Encoding to Base64
$BytesCredentials = [System.Text.Encoding]::ASCII.GetBytes($credentials)
$EncodedCredentials = [Convert]::ToBase64String($BytesCredentials)

# Authorizatioin header value 
$auth = "Basic $( $EncodedCredentials )"

# Encrypting Authorization header
$credentialsEncrypted = Get-PlaintextToSecure $auth

$login = @{
    "authenticationHeader" = $credentialsEncrypted
}


#-----------------------------------------------
# SETTINGS INXMAIL
#-----------------------------------------------
$settings = @{
    "base" = "https://api.inxmail.com/$base/rest/v1/"
    "encoding" = "UTF8"
    "login" = $login
    "logfile" = "$( $scriptPath )\inxmail.log"
    "nameConcatChar" = " / "
    "approved" = $true
    "sendMailing" = $false
}


################################################
#
# PACK TOGETHER SETTINGS AND SAVE AS JSON
#
################################################

# create json object
# weil json-Dateien sind sehr einfach portabel
$json = $settings | ConvertTo-Json -Depth 8 # -compress

# print settings to console
$json

# save settings to file
$json | Set-Content -path "$( $scriptPath )\$( $settingsFilename )" -Encoding UTF8




