﻿################################################
#
# INPUT
#
################################################
<#
Param(
    [hashtable] $params
)
#>

#-----------------------------------------------
# DEBUG SWITCH
#-----------------------------------------------

$debug = $false


################################################
#
# NOTES
#
################################################



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
$libSubfolder = "lib"
$settingsFilename = "settings.json"
$moduleName = "FLXRESPONSE"
$processId = [guid]::NewGuid()

if ( $params.settingsFile -ne $null ) {
    # Load settings file from parameters
    $settings = Get-Content -Path "$( $params.settingsFile )" -Encoding UTF8 -Raw | ConvertFrom-Json
} else {
    # Load default settings
    $settings = Get-Content -Path "$( $scriptPath )\$( $settingsFilename )" -Encoding UTF8 -Raw | ConvertFrom-Json
}

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

# append a suffix, if in debug mode
if ( $debug ) {
    $logfile = "$( $logfile ).debug"
}

$exportFolder = $settings.responseSettings.responseFolder


################################################
#
# FUNCTIONS & ASSEMBLIES
#
################################################

# Load all PowerShell Code
"Loading..."
Get-ChildItem -Path ".\$( $functionsSubfolder )" -Recurse -Include @("*.ps1") | ForEach {
    . $_.FullName
    "... $( $_.FullName )"
}
<#
# Load all exe files in subfolder
$libExecutables = Get-ChildItem -Path ".\$( $libSubfolder )" -Recurse -Include @("*.exe") 
$libExecutables | ForEach {
    "... $( $_.FullName )"
    
}
# Load dll files in subfolder
$libExecutables = Get-ChildItem -Path ".\$( $libSubfolder )" -Recurse -Include @("*.dll") 
$libExecutables | ForEach {
    "Loading $( $_.FullName )"
    [Reflection.Assembly]::LoadFile($_.FullName) 
}
#>


################################################
#
# LOG INPUT PARAMETERS
#
################################################

# Start the log
Write-Log -message "----------------------------------------------------"
Write-Log -message "$( $modulename )"
Write-Log -message "Got a file with these arguments:"
[Environment]::GetCommandLineArgs() | ForEach {
    Write-Log -message "    $( $_ -replace "`r|`n",'' )"
}
# Check if params object exists
if (Get-Variable "params" -Scope Global -ErrorAction SilentlyContinue) {
    $paramsExisting = $true
} else {
    $paramsExisting = $false
}

# Log the params, if existing
if ( $paramsExisting ) {
    Write-Log -message "Got these params object:"
    $params.Keys | ForEach-Object {
        $param = $_
        Write-Log -message "    ""$( $param )"" = ""$( $params[$param] )"""
    }
}



# is debug mode on?
Write-log -message "Debug mode is $( $debug )"


################################################
#
# PROGRAM
#
################################################


#"$( [datetime]::Now.ToString("yyyyMMddHHmmss") )`tUsing the recipient list $( $recipientListID )" >> $logfile


#-----------------------------------------------
# SETTINGS
#-----------------------------------------------

$sentsResponseTypes = [PSCustomObject]@{
    "campaignSent" = @{value="true";type="Boolean"}
    "campaignRead" = @{value="false";type="Boolean"}
    "campaignReadOnline" = @{value="false";type="Boolean"}
    "campaignLinkClicked" = @{value="false";type="Boolean"}
    "campaignLinkGroupClicked" = @{value="false";type="Boolean"}
    "campaignReadInfoPage" = @{value="false";type="Boolean"}
    "campaignFormVisited" = @{value="false";type="Boolean"}	
    "campaignFormSubmitted" = @{value="false";type="Boolean"}
    "campaignSurveyVisited" = @{value="false";type="Boolean"}
    "campaignSurveySubmitted" = @{value="false";type="Boolean"}
    "campaignForwardSubmitted" = @{value="false";type="Boolean"}
    "campaignForwardVisited" = @{value="false";type="Boolean"}
    "campaignNotSent" = @{value="false";type="Boolean"}
}

$opensResponseTypes = [PSCustomObject]@{
    "campaignSent" = @{value="false";type="Boolean"}
    "campaignRead" = @{value="true";type="Boolean"}
    "campaignReadOnline" = @{value="true";type="Boolean"}
    "campaignLinkClicked" = @{value="false";type="Boolean"}
    "campaignLinkGroupClicked" = @{value="false";type="Boolean"}
    "campaignReadInfoPage" = @{value="true";type="Boolean"}
    "campaignFormVisited" = @{value="false";type="Boolean"}	
    "campaignFormSubmitted" = @{value="false";type="Boolean"}
    "campaignSurveyVisited" = @{value="false";type="Boolean"}
    "campaignSurveySubmitted" = @{value="false";type="Boolean"}
    "campaignForwardSubmitted" = @{value="false";type="Boolean"}
    "campaignForwardVisited" = @{value="false";type="Boolean"}
    "campaignNotSent" = @{value="false";type="Boolean"}
}

$clicksResponseTypes = [PSCustomObject]@{
    "campaignSent" = @{value="false";type="Boolean"}
    "campaignRead" = @{value="false";type="Boolean"}
    "campaignReadOnline" = @{value="false";type="Boolean"}
    "campaignLinkClicked" = @{value="true";type="Boolean"}
    "campaignLinkGroupClicked" = @{value="true";type="Boolean"}
    "campaignReadInfoPage" = @{value="false";type="Boolean"}
    "campaignFormVisited" = @{value="false";type="Boolean"}	
    "campaignFormSubmitted" = @{value="false";type="Boolean"}
    "campaignSurveyVisited" = @{value="false";type="Boolean"}
    "campaignSurveySubmitted" = @{value="false";type="Boolean"}
    "campaignForwardSubmitted" = @{value="false";type="Boolean"}
    "campaignForwardVisited" = @{value="false";type="Boolean"}
    "campaignNotSent" = @{value="false";type="Boolean"}
}

$responseTypes = [HashTable]@{
    "sents"=$sentsResponseTypes
    "opens"=$opensResponseTypes
    "clicks"=$clicksResponseTypes
}

# Date ranges to load
$endDate = [datetime]::UtcNow
$startDate = $endDate.AddDays( -1 * $settings.responseSettings.daysToLoad )

$endDateFormatted = $endDate.ToString($settings.responseSettings.dateFormat)
$startDateFormatted = $startDate.ToString($settings.responseSettings.dateFormat)

# log
Write-log -message "Load responses in timeframe from $( $startDateFormatted ) until $( $endDateFormatted )"

#-----------------------------------------------
# GET CAMPAIGN HISTORY
#-----------------------------------------------

# ask for campaigns to download
if ( $debug ) {
    $campaigns = Invoke-Flexmail -method "GetCampaigns"
    $campaignArray = $campaigns | Out-GridView -PassThru # example id is: 7275152   
    $campaignArray = $campaignArray.campaignId

    # use the default settings
} else {
    $campaignArray = $settings.responseSettings.campaignsToDownload  
}


#-----------------------------------------------
# LOAD RESPONSE DATA
#-----------------------------------------------

$clicks = @()
$opens = @()
$sents = @()
$responseTypes.Keys | ForEach {

    $responseTypeName = $_
    $responseTypeValue = $responseTypes[$responseTypeName]

    $campaignArray | ForEach {
        
        $campaign = $_

        $historyParams = @{
            "campaignId"=@{
                "value"=$campaign
                "type"="int"
             }
             "timestampFrom"=$startDateFormatted
             "timestampTill"=$endDateFormatted
             "campaignHistoryOptionsType"=@{value=$responseTypeValue;type="campaignHistoryOptionsType"}
             
        }

        # log
        Write-log -message "Load campaign $( $campaign ) with response type $( $responseTypeName )"

        $campHistory = Invoke-Flexmail -method "GetCampaignHistory" -param $historyParams -verboseCall -responseType "EmailAddressHistoryActionType"

        # log
        Write-log -message "Loaded $( $campHistory.count ) $( $responseTypeName )"

        switch ( $responseTypeName ) {
        
            "clicks" {

                $clicks +=  [array]$campHistory | select @{name="campaignId";expression={ $campaign }},
                            @{name="actionId";expression={ $_.actionId.InnerText }},
                            @{name="timestamp";expression={ $_.timestamp.InnerText }},
                            @{name="linkKey";expression={ $_.link.Key.InnerText }},
                            @{name="linkUrl";expression={ $_.link.value.InnerText }},
                            @{name="flexmailId";expression={ $_.emailAddressType.flexmailId.InnerText }},
                            @{name="emailAddress";expression={ $_.emailAddressType.emailAddress.InnerText }}
            }

            "opens" {
                
                $opens += [array]$campHistory | select @{name="campaignId";expression={ $campaign }},
                            @{name="actionId";expression={ $_.actionId.InnerText }},
                            @{name="timestamp";expression={ $_.timestamp.InnerText }},
                            @{name="flexmailId";expression={ $_.emailAddressType.flexmailId.InnerText }},
                            @{name="emailAddress";expression={ $_.emailAddressType.emailAddress.InnerText }}
                            
            }

            "sents" {
                
                $sents += [array]$campHistory | select @{name="campaignId";expression={ $campaign }},
                            @{name="actionId";expression={ $_.actionId.InnerText }},
                            @{name="timestamp";expression={ $_.timestamp.InnerText }},
                            @{name="flexmailId";expression={ $_.emailAddressType.flexmailId.InnerText }},
                            @{name="emailAddress";expression={ $_.emailAddressType.emailAddress.InnerText }}
                            
            }
                        
        }         
    }
}

#-----------------------------------------------
# CHECK EXPORT FOLDER
#-----------------------------------------------

if ( !(Test-Path -Path $exportFolder) ) {
    New-Item -Path $exportFolder -ItemType "Directory"
}
#Set-Location -Path $exportFolder

# Archive all files in that folder first
$reponseFiles = Get-ChildItem -Path "$( $exportFolder )" -File
if ( $reponseFiles.Count -gt 0 ) {

    $exportTimestamp = [datetime]::Now.ToString("yyyyMMddHHmmss")

    # log
    Write-log -message "There are already $( $reponseFiles.Count ) files in response folder. Archiving them into $( $exportTimestamp )"

    New-Item -Path "$( $exportFolder )\$( $exportTimestamp )" -ItemType "Directory"
    $reponseFiles | Move-Item -Destination "$( $exportFolder )\$( $exportTimestamp )"

}


#-----------------------------------------------
# EXPORT RESPONSE DATA
#-----------------------------------------------

# log
Write-log -message "Exporting response data now"


$opens | Export-Csv -Path "$( $exportFolder )\opens.csv" -Encoding UTF8 -Delimiter "`t" -NoTypeInformation
$clicks | Export-Csv -Path "$( $exportFolder )\clicks.csv" -Encoding UTF8 -Delimiter "`t" -NoTypeInformation
$sents | Export-Csv -Path "$( $exportFolder )\sents.csv" -Encoding UTF8 -Delimiter "`t" -NoTypeInformation

# log
Write-log -message "Response data exported. Done!"


#-----------------------------------------------
# DOWNLOAD UNSUBSCRIBES, BOUNCES, BLACKLISTED
#-----------------------------------------------
# hints: https://flexmail.be/nl/api/manual/service/16-getemailaddresses
<#
$recipientListID = $settings.masterListId

# TODO [ ] Implement and test this response download scenario

# TODO [ ] put this into settings
$stateTypes = [array]@("unsubscribed", "bounced-out", "blacklisted") # unsubscribed, bounced-out, blacklisted, awaiting-opt-in-confirmation

$stateTypes | ForEach {
    
    $state = $_

    # TODO [ ] Implement paging
    $i = 1
    Do {

        $page = @{
            "items"=$settings.rowsPerUpload
            "page"=$i
        }

        $emailsParams = @{
            "mailingListIds"=[array]@($recipientListID)  #$mailingList.mailingListId
            "limit"=@{value=$page;type="Pagination"}
            "states"=[array]@($state) 
        }

        $emails = Invoke-Flexmail -method "GetEmailAddresses" -param $emailsParams

        $i += 1

    } While ( $emails.Count -eq $page.items )

}
#>

#-----------------------------------------------
# EXPORT LIST DATA
#-----------------------------------------------

# TODO [ ] Implement export of states

#-----------------------------------------------
# PUT RESPONSE IN DATABASE
#-----------------------------------------------

# TODO [ ] Trigger FERGE to deduplicate and load response into the database
