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
	[int]$AdditionalServerCount = 1

	)
	
$l = Import-Csv SiteDatabase.csv | ? {$_.SiteName -eq $SiteName }


if($l -eq $null){
	Write-Error "Error: Site is not provisioned"
	Exit
}

$l.DeployedServers = $l.DeployedServers.Split(' ')
$ServerList = $l.DeployedServers

$AttemptedServerList = @()

while($ServerList.Count -gt 0 -and $ServerList -ne $null -and $ServerList.Count -gt $l.DeployedServers.Length-$AdditionalServerCount){
	#Continue until we have enough servers or run out of servers to try :(
	$ThisServer = $ServerList | ? {$AttemptedServerList -notcontains $_} | Get-Random
	$AttemptedServerList += ($ThisServer)
	
	./Tool-LBDeprovisionServer.ps1 -SiteName $SiteName -ServerName $ThisServer
	#If we're removing the last server, we have to remove the backend or we'll throw errors in haproxy.
	if($ServerList.Length -eq 1 -or $ServerList -eq $null){
		./Tool-LBDeprovisionSite.ps1 -SiteName $SiteName			
	}
	./Tool-LBCompileConfigAndReload.ps1

	./Tool-WindowsDeprovisionServer.ps1 -SiteName $SiteName -Server $ThisServer
	$ServerList = @($ServerList | ? { $_ -ne $ThisServer })
	

	Write-Output "Successfully deprovisioned $SiteName from $ThisServer"

}

$old_csv = Import-Csv -Path SiteDatabase.csv | ? { $_.SiteName -ne $SiteName } 
'"SiteName","ZipFile","ServerCount","AutoScale","DeployedServers"' | Out-File -Encoding UTF8 -FilePath SiteDatabase.csv
if($old_csv -ne $null){
 	[array]$old_csv | ConvertTo-Csv -NoTypeInformation | Select -Skip 1 | Out-file -Append -Encoding UTF8 -FilePath SiteDatabase.csv 
}
if($ServerList.Length -ne 0 -or $ServerList -eq $null){
	"""$SiteName"",""$($l.ZipFile)"",""$($l.ServerCount)"",""$($l.AutoScale)"",""$ServerList""" | Out-File -Append -Encoding UTF8 -FilePath SiteDatabase.csv
}





