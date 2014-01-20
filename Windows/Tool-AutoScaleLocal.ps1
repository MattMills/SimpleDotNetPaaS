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


$CPULoad = Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Select -Expand Average

$PreviousCPUDetail = Import-CSV C:\PaaS-AutoScale-History.csv
$owners = @{}
gwmi win32_process |?{$_.Name -eq 'w3wp.exe' -or $_.Name -eq 'php-cgi.exe' } |% {$owners[$_.handle] = $_.getowner().user}
$CurrentCPUDetail = [array](get-process |? {$_.Name -eq 'w3wp' -or $_.Name -eq 'php-cgi' } | select CPU,Id,@{l="Owner";e={$owners[$_.id.tostring()]}})
if($CurrentCPUDetail -eq $null ) { Exit} #Nothing running here
foreach($x in $CurrentCPUDetail){
		$y = $PreviousCPUDetail | Where { $_.Id -eq $x.Id }
		if($y -eq $null){
			$lastCPU = 0
		}else{
			$lastCPU = $y.CPU
		}
		Add-Member -MemberType NoteProperty -InputObject $x -Name 'CPUThisPeriod' -Value ($x.CPU-$lastCPU)
	}
	
$CurrentCPUDetail | Export-CSV C:\PaaS-AutoScale-History.csv -NoTypeInformation -Encoding UTF8


$totalCurrentCPUTime = $CurrentCPUDetail | Measure-Object CPUThisPeriod -Sum | Select -ExpandProperty Sum
$totalPreviousCPUTime = $PreviousCPUDetail | Measure-Object CPUThisPeriod -Sum | Select -ExpandProperty Sum


foreach($x in $CurrentCPUDetail){
	$y = $x.CPUThisPeriod
	$site = $x.Owner.Substring(5)
	#Only worry about scaling up if we're at a moderate load
	if($x.Owner -notlike 'PaaS-*'){ continue }
	if($CPULoad -gt 40 -and $y -gt 1 -and ($y/$totalCurrentCPUTime) -gt 0.20){
		"SCALE $site"		
	}elseif($y -lt 0.1){
		"IDLE $site"
	}
}

