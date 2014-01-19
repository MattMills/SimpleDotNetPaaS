# SimpleDotNetPaaS
#
# Copyright (C) 2014  Matt Mills
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see [http://www.gnu.org/licenses/].


Param(
[Parameter(Mandatory=$true)] [string]$ZipFile,
[Parameter(Mandatory=$true)] [string]$SiteName,
[Parameter(Mandatory=$true)] [string]$Server
)


#MSFT Docs:
#http://www.iis.net/learn/web-hosting/web-server-for-shared-hosting/aspnet-20-35-shared-hosting-configuration
#http://msdn.microsoft.com/en-us/library/ms228096%28v=vs.100%29.aspx

if($SiteName -eq $null){
Write-Error "You must specify a SiteName"
Exit
}
if($Server -eq $null){	
Write-Error "You must specify a server "
Exit	
}
<#
!Push zip file to SERV
!unzip zip file on SERV
!Create user account
!Set App Pool FS security
!Create app pool
!Set website FS security
!Create-Website
Modify website configuration
Start website
Health test
!Notify load balancer of new site
!Confirm Load balancer acceptance 
Notify? of completion
#>

Function New-RemoteProcess {
Param(
	$ComputerName,
	$RemoteProcess
	)
	
$WMI = Get-WmiObject -list Win32_Process -ComputerName $ComputerName
$ReturnValue = $WMI.Create($RemoteProcess)

Return $ReturnValue.ReturnValue
}

Function New-LocalUser {
param (
	$UserName,
	$Password,
	$ComputerName
	)
	
$objOu = [ADSI]"WinNT://$ComputerName,Computer"
$objUser = $objOU.Create("User", $UserName)
$objUser.SetPassword($Password)
$objUser.SetInfo()
$objUser.Description = ".Net PaaS AppPool Auto created user"
$objUser.SetInfo()
$objUser.UserFlags = 64+65536 # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
$objUser.SetInfo()
}

$LocalSitePath = "C:\Sites"
$LocalAppPoolPath = "C:\AppPools"
$SitePath = "\\$Server\C$\Sites"
$AppPoolPath = "\\$Server\C$\AppPools"



if(! (Test-Path -Path $ZipFile)){
	Write-Error "Invalid path to Zip File"
	Exit
}
if(! (Test-Path -Path $SitePath) -or !(Test-PAth -Path $AppPoolPath)){
	Write-Error "Unable to access remove server $server or invalid config"
	Exit
}
if( (Test-Path -Path "$SitePath\$SiteName") -or (Test-Path -Path "$AppPoolPath\$SiteName")){
	Write-Error "Site already exists on specified server"
	Exit
}

#Deploy physical site content
$null = New-Item -ItemType Container "$SitePath\$SiteName"
$null = New-Item -ItemType Container "$AppPoolPath\$SiteName"


Copy-Item $ZipFile "$SitePath\$SiteName\"


#Create user account for AppPool
Add-Type -Assembly System.Web
$RandomPassword = [Web.Security.Membership]::GeneratePassword(64,16)

New-LocalUser -UserName "PaaS-$SiteName" -Password $RandomPassword -ComputerName $Server




try{
	$session = New-PSSession -ComputerName $Server
}catch {
	Write-Error "Unable to open PSSession to $Server"
	Exit
}
Invoke-Command -Session $session {
	Param ($ZipFile, $SiteName, $Server, $LocalSitePath, $LocalAppPoolPath, $RandomPassword)
	
	$7zipPath = "C:\Program Files (x86)\7-Zip\7z.exe"
	$ZipName = Split-Path -Leaf $ZipFile

	$ret = &"$7zipPath" "x" "$LocalSitepath\$SiteName\$ZipName" "-o$LocalSitePath\$SiteName\"

	Remove-Item -Force -Path "$LocalSitePath\$SiteName\$ZipName"

	
	#Add user to group that gives them LognoBatch and LogonService
	([ADSI]"WinNT://$Server/LogonAsBatch").Add("WinNT://$Server/PaaS-$SiteName")
	([ADSI]"WinNT://$Server/LogonAsService").Add("WinNT://$Server/PaaS-$SiteName")

	#Set App Pool FS security
	#ACL Prep
	$InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
	$PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
	$objType = [System.Security.AccessControl.AccessControlType]::Allow 

	$acl = Get-Acl "$LocalAppPoolPath\$SiteName"
	$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule "PaaS-$SiteName","Modify", $InheritanceFlag, $PropagationFlag, $objType
	$acl.SetAccessRule($accessRule)
	Set-Acl "$LocalAppPoolPath\$SiteName" $acl

	#Set website FS security
	$acl = Get-Acl "$LocalSitePath\$SiteName"
	$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule "PaaS-$SiteName","Modify", $InheritanceFlag, $PropagationFlag, $objType
	$acl.SetAccessRule($accessRule)
	Set-Acl "$LocalSitePath\$SiteName" $acl
	
	#Create app pool
	#Get IIS tools
	if ([System.Version] (Get-ItemProperty -path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion").CurrentVersion -ge [System.Version] "6.1") {
		$null = Import-Module WebAdministration 
	} else { 
		if( (Get-PSSnapin -Name WebAdministration -ErrorAction SilentlyContinue) -eq $null ){
			$null = Add-PSSnapin WebAdministration | Out-Null
		}
	}

	$null = New-WebAppPool -Name "PaaS-$SiteName"

	$pool = Get-Item "IIS:\AppPools\PaaS-$SiteName"

	$pool.processModel.username = "$Server\PaaS-$SiteName"
	$pool.processModel.password = "$RandomPassword"
	$pool.processModel.identityType = 3

	$pool | set-item 

	$null = Restart-WebAppPool "PaaS-$SiteName"
	#Create-Website

	$null = New-Website -Name "PaaS-$SiteName" -HostHeader $SiteName -PhysicalPath "$LocalSitePath\$SiteName" -ApplicationPool "PaaS-$SiteName"
} -ArgumentList $ZipFile, $SiteName, $Server, $LocalSitePath, $LocalAppPoolPath, $RandomPassword
Remove-PSSession $session
#Modify website configuration
#Start website
$null = New-Item -ItemType File "$SitePath\$SiteName\health.html"