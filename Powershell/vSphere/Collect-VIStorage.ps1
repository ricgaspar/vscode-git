# ---------------------------------------------------------
#
#
# ---------------------------------------------------------
clear
# ---------------------------------------------------------
# Pre-defined variables
$Global:SECDUMP_SQLServer = "s001.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

# ---------------------------------------------------------

Function Gather-VM-Storage {
	Echo-Log "Gathering VM storage information"	
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($conn.state -eq "Closed") { exit }   	

	$query = "delete from vmstorage"
	$data = Query-SQL $query $SQLconn
		
	ForEach ($vm in (Get-VM | Sort Name)) {
		$VMView = $vm | Get-View 
		Echo-Log $VM.Name
		ForEach ($VirtualSCSIController in ($VMView.Config.Hardware.Device | Where {$_.DeviceInfo.Label -match "SCSI Controller"})) {
			ForEach ($VirtualDiskDevice  in ($VMView.Config.Hardware.Device | Where {$_.ControllerKey -eq $VirtualSCSIController.Key})) {
			
			$query = "insert into vmstorage " +
         	"(systemname, domainname, poldatetime, PowerState, HostName, VMID, FileName, Label, Capacity, SCSIBus, SCSILogicalUnit)" +
         	" VALUES ( " + 
			"'" + $VM.Name + "'," + 
			"'" + $Env:USERDOMAIN + "',GetDate()," +
           	"'" + $VM.PowerState + "'," +
           	"'" + $VMView.Guest.HostName + "'," +
			"'" + $VM.ID + "'," +
           	"'" + $VirtualDiskDevice.Backing.FileName + "'," +
           	"'" + $VirtualDiskDevice.DeviceInfo.Label + "'," +
           	($VirtualDiskDevice.CapacityInKB * 1KB) + "," +
           	$VirtualSCSIController.BusNumber + "," +
           	$VirtualDiskDevice.UnitNumber + ")"			
		  	$data = Query-SQL $query $SQLconn
			# if ($data.gettype() -eq [int]) {Error-Log "Failed to query SQL server.";EXIT}		
			}
		}
	Clear-Variable $VMView -ErrorAction SilentlyContinue
	}
}

Function Gather-DS-Storage {
	Echo-Log "Gathering datastores information"
	
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($conn.state -eq "Closed") { exit }  
	
	$query = "delete from dsstorage"
	$data = Query-SQL $query $SQLconn
	
	$query = "delete from dsvm"
	$data = Query-SQL $query $SQLconn
	
	$Datastores = Get-Datastore | Sort Name
	
	# Loop through Datastores
	ForEach ($Datastore in $Datastores) {		
		Echo-Log $Datastore.Name
		$DSView = $Datastore | Get-View
		
	 	ForEach($vm in $DSView.vm) {
			$query = "insert into dsvm " +
         		"(DatastoreID, VMID) VALUES (" +
				"'" + $Datastore.ID + "'," +
				"'" + $vm.value + "')"
			$data = Query-SQL $query $SQLconn
		}
		
		$query = "insert into dsstorage " +
         	"(DataCenter, DataCenterID, poldatetime, ID, Name, VMFSVersion, Capacity, Freespace )" +
         	" VALUES ( " + 
			"'" + $Datastore.Datacenter.Name + "'," + 
			"'" + $Datastore.DatacenterID + "'," + 
			"GetDate()," +
           	"'" + $Datastore.ID + "'," +
           	"'" + $DSView.Name + "'," +
			"'" + $DSView.Info.Vmfs.Version + "'," +
           	$DSView.Summary.Capacity + "," +
           	$DSView.Summary.Freespace + ")"			
			
		$data = Query-SQL $query $SQLconn		
	}
}

# ---------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName"  
$VCServer = "S009"
Echo-Log "Connecting to Virtual Center"

Add-PSSnapin VMware.VimAutomation.Core
$VC = Connect-VIServer $VCServer -User "nedcar\Adm1" -password "J0m4w1@gdc"

Gather-VM-Storage
Gather-DS-Storage

Disconnect-VIServer -Confirm:$False

