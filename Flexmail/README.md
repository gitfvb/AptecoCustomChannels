# Dependencies

* Make sure PS Version 5.1 is installed at Minimum (which is normally pre-installed with Windows Server)
  * You can see it in Powershell if you type in ```$PSVersionTable```
  * If PSVersion < 5.1, then install this one: https://www.microsoft.com/en-us/download/details.aspx?id=54616
  * And restart the machine



# Getting Started

1. Download all the files in a directoy
1. Put those files somewhere on your Apteco server where the faststats service is running or where that directoy can be read

# Setup

## Scripts

1. Open the file "flexmail__00__create_settings.ps1" and execute the script. It will ask you for the path of the settings and log file. Also your Flexmail client id, which is in the login object and the password
1. Run that file and you will be asked for the Flexmail token. This one will be encrypted and only accessible by the server that runs that script. A "settings.json" file will be created where you have set this up and a "aes.key" file in the script directory.

## Channel Editor

1. Open up your channel editor, create a new channel and choose "PowerShell". Username and Password are only dummy values. Please ensure the email address is overridden by "emailAddress" ![2019-12-19 18_35_20-Clipboard](https://user-images.githubusercontent.com/14135678/71195612-30541400-2286-11ea-8d20-c78410ec4e0e.png)
1. Change all the linked directories here. The integration parameters are multiple additional parameters that can be send to the PowerShell scripts.<br/><br/>![2019-12-19 18_40_08-Channel-Editor](https://user-images.githubusercontent.com/14135678/71195846-a6f11180-2286-11ea-82d6-915c10e2b5ac.png)<br/>Please make sure in the `IntegrationParameters` you enter the `scriptPath` and `settingsFile` like `scriptPath=D:\Apteco\scripts\flexmail;settingsFile=D:\Apteco\scripts\flexmail\settings.json`<br/>With this `settingsFile` Parameter you are able to reuse the same script files with different settings saved in the json file
1. Add more variables here. Please ensure you use the standard parameter names from Flexmail https://flexmail.be/en/api/manual/type/12-emailaddresstype ![2019-12-19 18_41_56-](https://user-images.githubusercontent.com/14135678/71195967-e7508f80-2286-11ea-9726-4f01303e0d0c.png)
1. More variables can be added on the fly in the content element in the campaign or the campaign attributes. You can also use custom fields to refer to. The script will automatically handle existing custom fields. At the moment there are only string based custom fields allowed (no nested arrays).

## Response Download

1. The response download via "FERGE" is not triggered automatically by PeopleStage, by can be done through a "Scheduled Task" in Windows. Just trigger "flexmail__50__responses.ps1" n times a day and the response data will be downloaded.
1. Triggering FERGE to put the response data into the database is not implemented in this example yet.

Note: The downloaded response with type "unsubscribed", "bounced-out", "blacklisted" don't have a campaign reference in Flexmail, so they have to be selected via FastStats and Orbit.

# First Campaign

1. Create a normal campaign and choose your mailing in the delivery step and enter an ID of a source, that is available in Flexmail. If no source valid value is provided, the campaign will throw an exception and will stop and wait for the users interaction. ![2019-12-19 18_46_08-Apteco PeopleStage - Handel](https://user-images.githubusercontent.com/14135678/71196310-b58bf880-2287-11ea-9348-0bd5497f6e66.png)

1. The first time any of the scripts are getting called, a "flexmail.log" file will be created as well as an upload directoy where you can proove the uploaded files.

# Exceptions

* If no source valid value is provided, the campaign will throw an exception and will stop and wait for the users interaction.
![2019-12-19 18_19_10-Apteco PeopleStage - Handel](https://user-images.githubusercontent.com/14135678/71196433-fab02a80-2287-11ea-99f3-73d51a946d58.png)
