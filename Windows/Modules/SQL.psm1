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

#FIXME: SQL Injection
#TODO: Do these as factories instead of seperate functions


function Get-SQLConnection {
	$connectionString = "Server=10.5.2.202;uid=SimpleDotNetPaaS;pwd=thisispaas;Database=SimpleDotNetPaaS;Integrated Security=False;"

	$connection = New-Object System.Data.SqlClient.SqlConnection
	$connection.ConnectionString = $connectionString

	$connection.Open()
	
	return $connection
}
function SQLQuery {
	param($Query, $dbc)
	
	$da = New-Object System.Data.SqlClient.SqlDataAdapter
	$dt = New-Object System.Data.DataTable
	$cmd = New-Object System.Data.SqlClient.SqlCommand
	$cmd.CommandText = $Query
	$cmd.Connection = $dbc
	$da.SelectCommand = $cmd
	
	$output = $da.Fill($dt)
	return $dt	
}
function Get-PaaSServers {
	param(
		$ServerID = $null,
		$ServerName = $null,
		$Status = $null,
		$dbc
		)
	
	$Query = "Select * from Servers"
	$Where = " Where "
	
	if($ServerID -ne $null){
		$Where += " ServerID='$ServerID' AND "
	}
	
	if($ServerName -ne $null){
		$Where += " ServerName='$ServerName' AND "
	}
	
	if($Status -ne $null){
		$Where += " Status='$Status' AND "
	}
	$Where = $Where.Substring(0, $Where.Length-5)
	
	if($Where -eq " Where "){ $Where = ""}
	
	$Query += $Where
	return SQLQuery $Query $dbc
}
function Get-PaaSSites {
	param(
		$SiteID = $null,
		$SiteName = $null,
		$SiteContent = $null,
		$ServerCount = $null,
		$AutoScale = $null,
		$dbc
		)
	
	$Query = "Select * from Sites"
	$Where = " Where "
	
	if($SiteID -ne $null){
		$Where += " SiteID='$SiteID' AND "
	}
	
	if($SiteName -ne $null){
		$Where += " SiteName='$SiteName' AND "
	}
	
	if($SiteContent -ne $null){
		$Where += " SiteContent='$SiteContent' AND "
	}
	
	if($ServerCount -ne $null){
		$Where += " ServerCount='$ServerCount' AND "
	}
	
	if($AutoScale -ne $null){
		$Where += " AutoScale='$AutoScale' AND "
	}
	$Where = $Where.Substring(0, $Where.Length-5)
	
	if($Where -eq " Where "){ $Where = ""}
	
	$Query += $Where
	return SQLQuery $Query $dbc
}
function Get-PaaSSiteToServer {
	param(
		$SiteID = $null,
		$ServerID = $null,
		$Status = $null,
		$dbc
		)
	
	$Query = "Select * from SitesToServers"
	$Where = " Where "
	
	if($SiteID -ne $null){
		$Where += " SiteID='$SiteID' AND "
	}
	
	if($ServerID -ne $null){
		$Where += " ServerID='$ServerID' AND "
	}
	
	if($Status -ne $null){
		$Where += " Status='$Status' AND "
	}
	$Where = $Where.Substring(0, $Where.Length-5)
	
	if($Where -eq " Where "){ $Where = ""}
	
	$Query += $Where
	return SQLQuery $Query $dbc
}
function New-PaaSServer{
	param(
		[Parameter(Mandatory=$True)][string]$ServerName,
		[int]$Status = 0,
		$dbc
	)
	
	$Query = "INSERT INTO Servers (ServerName, Status) OUTPUT INSERTED.ServerID values ('$ServerName', '$Status') "
	
	return (SQLQuery $Query $dbc).ServerID
}
function New-PaaSSite{
	param(
		[Parameter(Mandatory=$True)][string]$SiteName,
		[Parameter(Mandatory=$True)][string]$SiteContent,
		[int]$ServerCount = 1,
		[int]$AutoScale = 0,
		$dbc
	)
	
	$Query = "INSERT INTO Sites (SiteName, SiteContent, ServerCount, AutoScale) OUTPUT INSERTED.SiteID values ('$SiteName', '$SiteContent', '$ServerCount', '$AutoScale') "
	
	return (SQLQuery $Query $dbc).SiteID
}
function New-PaaSSiteToServer{
	param(
		[Parameter(Mandatory=$True)][int]$SiteID,
		[Parameter(Mandatory=$True)][int]$ServerID,
		[int] $Status=0,
		$dbc
	)
	
	$Query = "INSERT INTO SitesToServers (SiteID, ServerID, Status) values ('$SiteID','$ServerID', '$Status') "
	

	SQLQuery $Query $dbc
	return $True
}
function Remove-PaaSServer {
	param(
		[Parameter(Mandatory=$True)][int]$ServerID = $null,
		$dbc
		)
	
	$Query = "DELETE from Servers WHERE ServerID='$ServerID'"

	SQLQuery $Query $dbc
	return $True
}
function Remove-PaaSSite {
	param(
		[Parameter(Mandatory=$True)][int]$SiteID,
		$dbc
		)
	
	$Query = "DELETE from Sites WHERE SiteID='$SiteID'"
		
	SQLQuery $Query $dbc
	return $True
}
function Remove-PaaSSiteToServer {
	param(
		[Parameter(Mandatory=$True)][int]$SiteID,
		[Parameter(Mandatory=$True)][int]$ServerID,
		$dbc
		)
	
	$Query = "DELETE from SitesToServers Where  SiteID='$SiteID' AND ServerID='$ServerID'"
	SQLQuery $Query $dbc
	
	return $True
}
function Set-PaaSSite {
	param(
		[Parameter(Mandatory=$True)][int]$SiteID,
		$SiteName = $null,
		$SiteContent = $null,
		$ServerCount = $null,
		$AutoScale = $null,
		$dbc
		)
	
	
	$Updates = ''
	
	if($SiteName -ne $null){
		$Updates += "SiteName='$SiteName',"
	}
	
	if($SiteContent -ne $null){
		$Updates += "SiteContent='$SiteContent',"
	}
	
	if($ServerCount -ne $null){
		$Updates += "ServerCount='$ServerCount',"
	}
	
	if($AutoScale -ne $null){
		$Updates += "AutoScale='$AutoScale',"
	}
	
	if($Updates -eq '') { Return $False} #We cant update without anything to update >_>
	$Updates = $Updates.Substring(0, $Updates.Length-1)
	
	$Query = "UPDATE Sites set $Updates WHERE SiteID='$SiteId'"
	SQLQuery $Query $dbc
	return $True
}

Export-ModuleMember -Function Get-SQLConnection

Export-ModuleMember -Function Get-PaaSServers
Export-ModuleMember -Function Get-PaaSSites
Export-ModuleMember -Function Get-PaaSSiteToServer

Export-ModuleMember -Function New-PaaSServer
Export-ModuleMember -Function New-PaaSSite
Export-ModuleMember -Function New-PaaSSiteToServer

Export-ModuleMember -Function Remove-PaaSServer
Export-ModuleMember -Function Remove-PaaSSite
Export-ModuleMember -Function Remove-PaaSSiteToServer

Export-ModuleMember -Function Set-PaaSSite