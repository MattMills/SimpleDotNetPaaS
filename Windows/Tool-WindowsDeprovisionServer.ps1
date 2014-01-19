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
	[Parameter(Mandatory=$true)] [string]$SiteName,
	[Parameter(Mandatory=$true)] [string]$Server
)

if($SiteName -eq $null){
	Write-Error "You must specify a SiteName"
	Exit
}
if($Server -eq $null){	
	Write-Error "You must specify a server "
	Exit	
}

$LocalSitePath = "C:\Sites"
$LocalAppPoolPath = "C:\AppPools"
$SitePath = "\\$Server\C$\Sites"
$AppPoolPath = "\\$Server\C$\AppPools"



if(! (Test-Path -Path $SitePath) -or !(Test-PAth -Path $AppPoolPath)){
	Write-Error "Unable to access remote server $server or invalid config"
	Exit
}
if( !(Test-Path -Path "$SitePath\$SiteName") -or !(Test-Path -Path "$AppPoolPath\$SiteName")){
	Write-Error "Site doesnt exists on specified server"
Exit
}

try{
	$session = New-PSSession -ComputerName $Server
}catch {
	Write-Error "Unable to open PSSession to $Server"
	Exit
}
Invoke-Command -Session $session {
	Param ($SiteName, $Server, $LocalSitePath, $LocalAppPoolPath)
	
	#Get IIS tools
	if ([System.Version] (Get-ItemProperty -path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion").CurrentVersion -ge [System.Version] "6.1") {
	$null = Import-Module WebAdministration 
	} else { 
		if( (Get-PSSnapin -Name WebAdministration -ErrorAction SilentlyContinue) -eq $null ){
			$null = Add-PSSnapin WebAdministration | Out-Null
		}
	}
	
	Stop-Website "PaaS-$SiteName"
	Remove-Website "PaaS-$SiteName" -Confirm:$false
	Remove-WebAppPool "PaaS-$SiteName" -Confirm:$false
	
	$ComputerName = $ENV:COMPUTERNAME
	$UserName = "PaaS-$SiteName"
	$objOu = [ADSI]"WinNT://$ComputerName,Computer"
	$objOu.psbase.invoke("Delete", "User", $UserName)
	
	#Deploy physical site content
	$null = Remove-Item -Recurse -Confirm:$false -Force "$LocalSitePath\$SiteName"
	$null = Remove-Item -Recurse -Confirm:$false -Force "$LocalAppPoolPath\$SiteName"	
} -ArgumentList $SiteName, $Server, $LocalSitePath, $LocalAppPoolPath
Remove-PSSession $session

