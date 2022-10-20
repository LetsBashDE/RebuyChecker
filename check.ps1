#
# Autor: LetsBash.de
# Description: Need a new phone and everything you want is out of stock? This script will check the Website for you!
# Requirements: Windows 10

# Give me the URL to look at
$urlwheretocheck = "https://www.rebuy.de/kaufen/handy-apple-iphone-12-pro?f_prop_rom=256%20GB&f_variant_availability=a4"

# Tell me what I should look for
$whattocheckfor  = "Apple iPhone 12 Pro 256GB"

# What should I tell you, when I found it?
$alerttitle      = "Rebuy"
$alerttext       = "Go buy!"


function Send-Notification {
    [cmdletbinding()]
    Param (
        [string]
        $AlertTitle,
        [string]
        [parameter(ValueFromPipeline)]
        $AlertText
    )

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $Template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
    $RawXml = [xml] $Template.GetXml()
    ($RawXml.toast.visual.binding.text|where {$_.id -eq "1"}).AppendChild($RawXml.CreateTextNode($AlertTitle)) > $null
    ($RawXml.toast.visual.binding.text|where {$_.id -eq "2"}).AppendChild($RawXml.CreateTextNode($AlertText)) > $null
    $SerializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $SerializedXml.LoadXml($RawXml.OuterXml)
    $AlertObject = [Windows.UI.Notifications.ToastNotification]::new($SerializedXml)
    $AlertObject.Tag = "PowerShell"
    $AlertObject.Group = "PowerShell"
    $AlertObject.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(5)
    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("PowerShell")
    $Notifier.Show($AlertObject);
}


function check {
    Param (
        [string]
        $url,
        [string]
        $check,
        [string]
        $atitle,
        [string]
        $atext
    )
    $webquery = New-Object -ComObject "Msxml2.ServerXMLHTTP.6.0"
    $webquery.SetOption(2, 'objHTTP.GetOption(2) - SXH_SERVER_CERT_IGNORE_ALL_SERVER_ERRORS')
    $webquery.open('GET', $url, $false)
    $webquery.SetRequestHeader("Pragma", "no-cache")
    $webquery.SetRequestHeader("Cache-Control", "no-cache")
    $webquery.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
    [long]$timeout = 10000
    $webquery.SetTimeouts($timeout,$timeout,$timeout,$timeout)
    $webquery.send()
    if($webquery.statusText -like "*OK*"){
        if($webquery.responseText -like ("*"+$check+"*")){
            Send-Notification $atitle $atext
            write-host
            write-host "FOUND!!! "
            read-host -Prompt "Anykey to open Browser"
            Start-Process $url
            write-host "Restart in 15 Minutes ..."
            start-sleep -Seconds 900
        }
    }

}

Write-Host "Looking for ..." -NoNewline
while(1){
    check $urlwheretocheck $whattocheckfor $alerttitle $alerttext
    write-host "." -NoNewline
    start-sleep -Seconds 15
}
