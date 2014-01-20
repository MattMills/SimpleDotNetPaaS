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

$l = Import-Csv SiteDatabase.csv
#if(($l | ? {$_.SiteName -eq $SiteName} | Measure).Count -eq 0){
#	Write-Error "Error: $SiteName is not provisioned"
#	Exit
#}

$ServerList = [array](Get-Content ServerList.txt)

$ScaleRequests = @()
$IdleSites = @()
foreach($Server in $ServerList){
	try{
		$session = New-PSSession -ComputerName $Server
	}catch {
		Write-Error "Unable to open PSSession to $Server"
		Exit
	}
	$output = Invoke-Command -Session $session -FilePath .\Tool-AutoScaleLocal.ps1
	
	foreach($line in $output){
		if($line -eq $null) {continue}
		if($line -like "SCALE*"){
			$site = $line.substring(6)
			$ScaleRequests += @($site)
		}elseif($line -like "IDLE*"){
			$site = $line.substring(5)
			$IdleSites += @($site)
		}
	}
	Remove-PSSession $session
}

$ScaleRequests = $ScaleRequests |Sort-Object -Unique
$IdleSites = $IdleSites | Sort-Object -Unique

foreach($site in $IdleSites){
	if($site -eq $null) { continue } #powerhsell sucks
	if($ScaleRequests -contains $site){
		Write-Output "Error: Got scale request for idle site $site"
		continue
	}
	$SiteDBEntry = $l | ? {$_.SiteName -eq $site}
	if($SiteDBEntry -eq $null){
		Write-Output "Error: Got idle for $Site which is not provisioned"
		continue
	}
	$SiteDBEntry.DeployedServers = $SiteDBEntry.DeployedServers.Split(' ')
	if($SiteDBEntry.DeployedServers.Count -le $SiteDBEntry.ServerCount){
		#Site already at minimum server count.
		continue
	}
	if($SiteDBEntry.AutoScale -eq "False"){
		#Site not confiugred for autoscale
		continue
	}
	
	.\Tool-DeprovisionAdditionalSite.ps1 -SiteName $site
}

foreach($site in $ScaleRequests){
	if($site -eq $null) { continue } #powerhsell sucks
	$SiteDBEntry = $l | ? {$_.SiteName -eq $site}
	if($SiteDBEntry -eq $null){
		Write-Output "Error: Got scale request for $Site which is not provisioned"
		continue
	}
	$SiteDBEntry.DeployedServers = $SiteDBEntry.DeployedServers.Split(' ')
	if($SiteDBEntry.DeployedServers.Count -ge $ServerList.Count){
		Write-Output "Error: Not enough servers to scale $site further"
		continue
	}
	if($SiteDBEntry.AutoScale -eq "False"){
		Write-Output "Warning: Got autoscale request for site that is not configured for autoscale"
		continue
	}
	
	.\Tool-ProvisionAdditionalSite.ps1 -SiteName $site
}
