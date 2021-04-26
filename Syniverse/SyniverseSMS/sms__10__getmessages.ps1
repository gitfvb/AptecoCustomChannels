################################################
#
# INPUT
#
################################################

Param(
    [hashtable] $params
)

#-----------------------------------------------
# DEBUG SWITCH
#-----------------------------------------------

$debug = $false

#-----------------------------------------------
# INPUT PARAMETERS, IF DEBUG IS TRUE
#-----------------------------------------------

if ( $debug ) {
    $params = [hashtable]@{
	    Password= "def"
	    scriptPath= "D:\Scripts\Syniverse\SMS"
	    Username= "abc"
    }
}


################################################
#
# NOTES
#
################################################

<#

TODO [ ] more logging
TODO [ ] replace mssql with already existent functions of EpiServer

#>

################################################
#
# SCRIPT ROOT
#
################################################

if ( $debug ) {
  # Load scriptpath
  if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
      $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
  } else {
      $scriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
  }
} else {
  $scriptPath = "$( $params.scriptPath )" 
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
$moduleName = "GETMAILINGS"
$processId = [guid]::NewGuid()
$timestamp = [datetime]::Now.ToString("yyyyMMddHHmmss")

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

# more settings
$logfile = $settings.logfile
$mssqlConnectionString = $settings.responseDB


# append a suffix, if in debug mode
if ( $debug ) {
  $logfile = "$( $logfile ).debug"
}


################################################
#
# FUNCTIONS
#
################################################

# TODO [ ] add mssql assemblies or extend it
Add-Type -AssemblyName System.Data #, System.Text.Encoding

Get-ChildItem -Path ".\$( $functionsSubfolder )" | ForEach {
  . $_.FullName
}


################################################
#
# LOG INPUT PARAMETERS
#
################################################

# Start the log
Write-Log -message "----------------------------------------------------"
Write-Log -message "$( $moduleName )"
Write-Log -message "Got a file with these arguments: $( [Environment]::GetCommandLineArgs() )"

# Check if params object exists
if (Get-Variable "params" -Scope Global -ErrorAction SilentlyContinue) {
  $paramsExisting = $true
} else {
  $paramsExisting = $false
}

# Log the params, if existing
if ( $paramsExisting ) {
  $params.Keys | ForEach-Object {
      $param = $_
      Write-Log -message "    $( $param )= ""$( $params[$param] )"""
  }
}


################################################
#
# CHECK MSSQL FOR TEMPLATES
#
################################################

#-----------------------------------------------
# LOAD TEMPLATES FROM MSSQL
#-----------------------------------------------

$mssqlConnection = New-Object System.Data.SqlClient.SqlConnection
$mssqlConnection.ConnectionString = $mssqlConnectionString

$mssqlConnection.Open()

"Trying to load the data from MSSQL"

# define query -> currently the age of the date in the query has to be less than 12 hours
$mssqlQuery = @"
SELECT *
FROM (
 SELECT *
  ,row_number() OVER (
   PARTITION BY CreativeTemplateId ORDER BY Revision DESC
   ) AS prio
 FROM [dbo].[CreativeTemplate]
 ) ct
WHERE ct.prio = '1' and MessageContentType = 'SMS'
ORDER BY CreatedOn
"@

# execute command
$mssqlCommand = $mssqlConnection.CreateCommand()
$mssqlCommand.CommandText = $mssqlQuery
$mssqlResult = $mssqlCommand.ExecuteReader()
    
# load data
$mssqlTable = new-object System.Data.DataTable
$mssqlTable.Load($mssqlResult)
    

$mssqlConnection.Close()

# show result
#$mssqlTable


#-----------------------------------------------
# TRANSFORM MSSQL RESULT INTO PSCUSTOMOBJECT
#-----------------------------------------------

$templates = @()
$mssqlTable | ForEach {

    $currentRow = $_

    $row = New-Object PSCustomObject

    $row | Add-Member -MemberType NoteProperty -Name "id" -Value $currentRow.CreativeTemplateId
    $row | Add-Member -MemberType NoteProperty -Name "name" -Value $currentRow.Name

    $templates += $row

}



###############################
#
# RETURN MESSAGES
#
###############################

return $templates