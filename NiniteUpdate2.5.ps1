
#Starts script and Ninite as if run by admin, needed to work. 
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
 
<# Original Idea by fen www.justfen.com // twitter.com/justfen_/ - github.com/justfen fen@justfen.com

Didn't work in the enviroment, nor how I wanted to control it.

Re-written to use config file, send email report, and be more useful -- by Matt Reece // matt.s.reece@gmail.com
#>

#Pull config file
Get-Content "C:\Ninite\NiniteUpdate.ini" | foreach-object -begin {$Settings=@{}} -process { $k = [regex]::split($_,'=='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $Settings.Add($k[0], $k[1]) } }

## Variables
# Used to identify network
$domainName = $Settings.Get_Item("Domain")

# Used to install on remote systems
$RemoteUser = $Settings.Get_Item("RemoteUser")
$RemotePass = $Settings.Get_Item("RemotePass")

## OU is used to determin which gorup of computers you want to update (so you dont update servers when you dont want to, just clients)
## An example would be "OU=Laptops,OU=Computers,DC=Just,DC=fen,DC=com"
## This would be equivalent to the following just.fen.com\Computers\Laptops
$OU = $Settings.Get_Item("OU")

# Save location of update log, so it can be saved by Ninite and then emailed.
$NiniteLog  = $Settings.Get_Item("Log")

# Install location of Ninite
$NiniteDir = $Settings.Get_Item("Ninite")

#Programs to Exclude in update.
$Exclude = $Settings.Get_Item("Exclude")

## Email Variables
$SmtpServer = $Settings.Get_Item("SmtpServer")
$SmtpPort = $Settings.Get_Item("SmtpPort")
$FromEmail = $Settings.Get_Item("FromEmail")
$ToEmail = $Settings.Get_Item("ToEmail")
$Pass = $Settings.Get_Item("FromPass")

$Run = "$NiniteDir /remote ad:$OU /remoteauth $RemoteUser $RemotePass /updateonly /exclude $Exclude /disableshortcuts /disableautoupdate /silent $NiniteLog"


function EmailReport() {
# Generate Attachment
$attachment = New-Object System.Net.Mail.Attachment($NiniteLog, 'text/plain')
# Construct and send email
$SmtpClient = new-object system.net.mail.smtpClient
$Msg = new-object Net.Mail.MailMessage
$SmtpClient.host = $SmtpServer
$SmtpClient.Port = $SmtpPort
$SmtpClient.Credentials = New-Object System.Net.NetworkCredential($FromEmail, $Pass)
$computer = gc env:computername
$Msg.From = $FromEmail
$Msg.To.Add($ToEmail)
$Msg.Subject = "Ninite Software Update Completed on " +$domainName +" Network "
$Msg.Body = "Ninite software update has completed on " +$domainName +" See report for details."
$Msg.Attachments.Add($attachment)
$SmtpClient.Send($Msg)

} 
#/exclude $Exclude

cmd /c "$Run"

EmailReport
