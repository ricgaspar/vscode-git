@{
GUID = "{3f86ae87-cb76-489d-ba6b-9c7c67fb0f6d}"
Author = "Marcel Jussen"
Description = "VDL Nedcar Born - Standard PS Library"
CompanyName = "VDL Nedcar - Information Management"
Copyright = "(c) 2013 - 2018 Marcel Jussen"
PowerShellVersion = "4.0"
ModuleVersion="3.0.0.0"
CLRVersion = "4.0"
NestedModules = 'VNB_FileSystem.psm1', `
	'VNB_Logging.psm1', `
	'VNB_Generic.psm1', `
	'VNB_CRC32.psm1', `
    'VNB_Cleanup.psm1', `
	'VNB_Registry.psm1', `
	'VNB_IP.psm1', `
	'VNB_INI.psm1', `
	'VNB_LocalSec.psm1', `
	'VNB_ActiveDirectory.psm1', `
	'VNB_MSSQL.psm1', `
	'VNB_DataSet.psm1', `	
	'VNB_Services.psm1', `
	'VNB_WUAU.psm1'
FunctionsToExport = '*'
CmdletsToExport = '*'
# VariablesToExport = '*'
AliasesToExport = '*'
}

