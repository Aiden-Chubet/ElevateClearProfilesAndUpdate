param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

'Running as Administrator'

## Clear old User profiles w/ exceptions

Set-ExecutionPolicy -ExecutionPolicy Bypass -Force

$ExcludedUsers = "Public", "Default", "Administrator", "PDQUser"
$LocalProfiles = Get-CimInstance -ClassName Win32_UserProfile | Where-Object { (!$_.Special) -and (!$_.Loaded) }

foreach ($LocalProfile in $LocalProfiles) {
    $ProfilePath = $LocalProfile.LocalPath.Replace("C:\Users\","")
    if (!($ExcludedUsers -contains $ProfilePath)) {
        $LocalProfile | Remove-CimInstance
        Write-Host "$ProfilePath Profile Deleted" -ForegroundColor Magenta
    }
}

## Download/install windows updates and reboot

Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
Install-Module -Name PSWindowsUpdate -Force
Get-Package -Name PSWindowsUpdate
Import-Module PSWindowsUpdate -Force
Get-WindowsUpdate -Download -AcceptAll
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot

Write-Host "Process complete" -ForegroundColor Magenta
