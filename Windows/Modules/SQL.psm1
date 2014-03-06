function SQLInit {
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
		$Where += " ServerID='$ServerID' "
	}
	
	if($ServerName -ne $null){
		if($ServerID -ne $null){
			$Where += "AND"
		}
		$Where += " ServerName='$ServerName' "
	}
	
	if($Status -ne $null){
		if($ServerID -ne $null -or $ServerName -ne $null){
			$Where += "AND"
		}
		$Where += " Status='$Status' "
	}
	if($Where -eq " Where "){ $Where = ""}
	
	$Query += $Where
	return SQLQuery $Query $dbc
}