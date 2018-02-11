#------------------------------------------------------------------
# Check Windows performance counters
#
# Author: Marcel Jussen
# (10-11-2014)
#
# Revised: 10-11-2014
#
#------------------------------------------------------------------

param (
    [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]$PerfMonCounterClass = 'Win32_PerfFormattedData_PerfDisk_LogicalDisk' ,
	
	[Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]$PerfMonCounterName = 'CurrentDiskQueueLength',
	
	[Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]$PerfMonCounterInstance = 'Name',
	
	[Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]$PerfMonCounterValue = 'C:',
	
	[Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [decimal]$PerfMonCounterMaxValue = 2,
	
	[Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [decimal]$PerfMonCounterWarnValue = 1.5 ,
	
	[Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [decimal]$PerfMonCounterCritValue = 2
)

$VERSION = "1.01"

$returnStateOK = 0
$returnStateWarning = 1
$returnStateCritical = 2
$returnStateUnknown = 3

# Default return value is Unknown
$ReturnVal = $returnStateUnknown

$PerfQuery = "Select $PerfMonCounterName from $PerfMonCounterClass where $PerfMonCounterInstance = '$PerfMonCounterValue'"
$PerfQueryResult = Get-WmiObject -Query $PerfQuery -ErrorAction SilentlyContinue

if($PerfQueryResult) {
	$PerfMonCounterReturnValue = [decimal]$PerfQueryResult."$PerfMonCounterName"	 
	
	# Evaluate return value
	if($PerfMonCounterReturnValue -ne $null) { 
		# Does the measured value exceed the maximum, this should never happen.
		if($PerfMonCounterReturnValue -ge $PerfMonCounterMaxValue) {
			$ReturnVal = $returnStateCritical
		} else {
			# Less than warn value? Everything is Ok.
			if($PerfMonCounterReturnValue -lt $PerfMonCounterWarnValue) { $ReturnVal = $returnStateOK }
			# Greater or equal warn value?
			if($PerfMonCounterReturnValue -ge $PerfMonCounterWarnValue) { $ReturnVal = $returnStateWarning }
			# Greater or equal critical value?
			if($PerfMonCounterReturnValue -ge $PerfMonCounterCritValue) { $ReturnVal = $returnStateCritical }
		}
	}
} else {
	$ReturnVal = $returnStateUnknown
}

switch($ReturnVal) {
	$returnStateOK {
		$Message = "$PerfMonCounterName OK"
	}
	
	$returnStateWarning {
		$Message = "$PerfMonCounterName Warning"
	}
	
	$returnStateCritical {
		$Message = "$PerfMonCounterName Critical"
	}
	
	$returnStateUnknown {
		$Message = "$PerfMonCounterName Unknown"
	}

	default {
		$Message = "$PerfMonCounterName Unknown"
	}
}

# Readable text
$Message += " - Value = $PerfMonCounterReturnValue"

# Performance text
$Message += " | $PerfMonCounterName=$PerfMonCounterReturnValue"
Write-Host $Message

exit $ReturnVal