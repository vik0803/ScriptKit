# This file is part of ScriptKit.
#
#    ScriptKit is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    ScriptKit is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with ScriptKit.  If not, see <http://www.gnu.org/licenses/>
#
###################################################################################################
# Title: Set Maximum Remote Console Sessions
# Filename:	set_vm_max_console_sessions.ps1
# Requires: set_vm_max_console_sessions-list.csv as VM name list input
# Created by: Rynardt Spies rynardt.spies@virtualvcp.com / www.virtualvcp.com / @rynardtspies
# Date: 20/02/2014 (Modified)
# Version: 1.00.01
# Description:	This script is used to set the maximum remote console sessions allowed on all
# virtual machines found in the servers.txt file. This is required by many financial industry
# to prevent more than one concurrent remote console session to a virtual machine in order to
# an administrator of a VM being shadowed remotely.
# Tested with: VMware PowerCLI 5.5 Release 1.
# Copyright (c) 2010 - 2014 Rynardt Spies
###################################################################################################

#Let's define some variables
$vcenter = "vcenter.domain" #Specify the vCenter server name
$infile = "set_vm_max_console_sessions-list.csv" #Specify the list of virtual machine names
$ReportFile = "c:\TEMP\set_vm_max_console_sessions-report.csv" #The results will be saved in this file
$ConsoleSessions = "1" #Specify the number of concurrent Remote Console Connections to allow per VM

Clear Screen
write-Output "Connecting to vSphere environment: $vcenter"
#Try to connect to $vcenter. If not, fail gracefully with a message
if (!($ConnectionResult = Connect-VIServer $vcenter -ErrorAction SilentlyContinue)){
	Write-Output "Could not connect to $vcenter"
	break
}
Write-Output "Successfully connected to: $ConnectionResult"

#Now, import the list of virtual machines from the provided csv file
Write-Output "Importing Virtual Machine list from $infile"
$vmlist = import-csv $infile

#Create the report variable array
$report = @();

foreach($vm in $vmlist){
	#Append a * to the end of the virtual machine name retrieved from the vcs file
    $vmwildcard = $vm.server + '*'
	$currentvmlist = Get-VM -Name $vmwildcard | Get-View
    #For each virtual machine found, set the maximum console connections
    foreach($currentvm in $currentvmlist){
		$currentvmname = $currentvm.name
		Write-Output "Setting maximum console sessions for $currentvmname to $consoleSessions"
		$vmAdvConfig = New-Object VMware.Vim.VirtualMachineConfigSpec
		$newSetting = New-Object VMware.Vim.optionvalue
		$newSetting.Key = "RemoteDisplay.maxConnections"
    	$newSetting.Value = $consoleSessions
    	$vmAdvConfig.extraconfig += $newSetting
		$currentvm.ReconfigVM($vmAdvConfig)
		
		#add change information to the report
		$row = "" | Select-Object VMName, New_Setting, New_Value
		$row.VMName = $currentvmname
		$row.New_Setting = $newSetting.Key
		$row.New_Value = $newSetting.Value
		$report += $row
		}
	}
#Write the results of the changes to a csv file.
Write-Output "Writing results to $ReportFile"
$report | Export-Csv $ReportFile -NoTypeInformation

Write-Output "In order for the changes to take effect, please power down each VM that was changed and power them back on."
#All done, disconnect from the VI Server
Write-Output "Disconnecting from $vcenter"
Disconnect-VIServer -confirm:$false



	