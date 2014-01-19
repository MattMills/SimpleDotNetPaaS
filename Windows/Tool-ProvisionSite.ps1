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


param(
	[Parameter(Mandatory=$true)][string]$SiteName,
	[Parameter(Mandatory=$true)][string]$ZipFile,
	[int]$ServerCount = 0,
	[switch]$AutoScale
	)
	
if($AutoScale -and $ServerCount -eq 0){
	$ServerCount = 2
}elseif(!$AutoScale -and $ServerCount -eq 0){
	$ServerCount = 1
}

$l = Import-Csv SiteDatabase.csv
if(($l | ? {$_.SiteName -eq $SiteName} | Measure).Count -ne 0){
	Write-Error "Error: $SiteName is already deployed"
	Exit
}

$ServerList = [array](Get-Content ServerList.txt)
$AttemptedServerList = @()
$SuccessfulServerList = @()

while($SuccessfulServerList.Count -lt $ServerCount -and $AttemptedServerList.Count -lt $ServerList.Count){
	#Continue until we have enough servers or run out of servers to try :(
	$ThisServer = $ServerList | ? {$AttemptedServerList -notcontains $_} | Get-Random
	$AttemptedServerList += ($ThisServer)
	
	
		./Tool-WindowsProvisionServer.ps1 -ZipFile $ZipFile -SiteName $SiteName -Server $ThisServer
		$SuccessfulServerList += @($ThisServer)
		Write-Output "Successfully deployed $SiteName to $ThisServer"
	#}catch{
	#	Write-Output "Failed to deploy $SiteName to $ThisServer"
	#}
}

"""$SiteName"",""$ZipFile"",""$ServerCount"",""$AutoScale"",""$SuccessfulServerList""" | Out-File -Append -Encoding UTF8 -FilePath SiteDatabase.csv
if((./Tool-LBProvisionSite.ps1 -SiteName $SiteName) -eq $false){
	Write-Error "Unable to provision site"
	exit
}
if($SuccessfulServerList.Count -eq 0){
	Write-Error "No servers provisioned"
	exit
}
foreach($Server in [array]$SuccessfulServerList){
	./Tool-LBProvisionServer.ps1 -SiteName $SiteName -ServerName $Server -ServerAddr "$($Server):80"
}

./Tool-LBCompileConfigAndReload.ps1


