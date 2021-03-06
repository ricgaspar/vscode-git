# ---------------------------------------------------------
#
# File System Functions
# Marcel Jussen
# 22-10-2013
#
# ---------------------------------------------------------

#
# Returns true if a folder is a root folder like C:\ or E:\
#
Function Is-Root-Folder {
	[cmdletbinding()]
	param(
		[ValidateNotNullOrEmpty()]
		[string]$Path
	)
		
	$a = New-Object -typename System.IO.DirectoryInfo $Path
	$retval = ($Path -eq $a.root.name)
    return $retval	
}


#
# Check if folder exists
#
function Exists-Dir {  
	param (
		[string]$Path
	)
    return ([IO.Directory]::Exists($Path))
}

#
# Check if file exists
#
function Exists-File {  
    param (
		[string]$Path
	)
    return ([IO.File]::Exists($Path))
}

#
# Create folder (and subfolders) if folder path does not exist
#
function Create-FolderStruct {
	param (
		[string]$Path
	)
	
	Try {
		$Test = Exists-Dir($path)
		if($Test) { 
			return 0 
		} else {
			$arr = $Path -split '\\'
			$drive = $arr[0]
			$NewPath = $drive
			foreach($fldr in $arr) {
				if($fldr -ne $drive) {
					$NewPath += ('\' + $fldr)
					$Test = Exists-Dir($NewPath)
					if ($Test -eq $false) {
						[Void][system.io.directory]::CreateDirectory($NewPath)
					}			
				}
			}
		}
	}
	Catch [System.Management.Automation.PSArgumentException] {
 			"invalid object"
	}
	Catch [system.exception] {
 			"caught a system exception"
	}
		
}

#
# Create hash with files by age.
#
function Files_ByAge {
	param (
		[string] $Path,
		[string] $Include = "*.*",
		[string] $Exclude = "",
		[int] $age_in_days = 0,
		[int] $Recurse = $false
	)

	$Now = Get-Date		
	$LastWrite = $Now.AddDays(- $Age_in_days)	
	
	# -Recurse parm is always needed when using -Include and/or -Exclude
	if ($Recurse -eq $True) {
		$Files = Get-ChildItem -path $Path -Include $Include -Exclude $Exclude -Recurse -Force -errorAction SilentlyContinue  |
			where {$_.psIsContainer -eq $false} | 
			where {$_.LastWriteTime -le "$LastWrite"}
	} else {		
		# When recursion of folders is not wanted make sure the directory name is equal to the folder path
		$Files = Get-ChildItem -path $Path -Include $Include -Exclude $Exclude -Recurse -Force -errorAction SilentlyContinue  |			
			where {$_.psIsContainer -eq $false} | 
			where {$_.DirectoryName -eq $Path} |
			where {$_.LastWriteTime -le "$LastWrite"}
	}		

	$Files = $Files | sort @{expression={$_.LastWriteTime};Descending=$true} 	
 	return $Files
}

#
# Create hash with folders by age.
#
function Folders_ByAge {
	param (
		[string] $Path,
		[string] $Include = "*",
		[string] $Exclude = "",
		[int] $age_in_days = 0,
		[int] $Recurse = $false
	)

	$Now = Get-Date		
	$LastWrite = $Now.AddDays(- $Age_in_days)
		
	# -Recurse parm is always needed when using -Include and/or -Exclude
	if ($Recurse -eq $True) {
		$Folders = Get-ChildItem -path $Path -Include $Include -Exclude $Exclude -Recurse -Force -errorAction SilentlyContinue  |
			where {$_.psIsContainer -eq $true} |
			where {$_.LastWriteTime -le "$LastWrite"}
	} else {
		# When recursion of folders is needed make sure the Parent name of the folder is equal to the leaf name of the path
		$LeafFolder = Split-Path $Path -Leaf
		$Folders = Get-ChildItem -path $Path -Include $Include -Exclude $Exclude -Recurse -Force -errorAction SilentlyContinue  |
			where {$_.psIsContainer -eq $true} |
			where {$_.Parent.name -eq $LeafFolder} |
			where {$_.LastWriteTime -le "$LastWrite"}
	}

	$Folders = $Folders | sort @{expression={$_.LastWriteTime};Descending=$true} 
 	return $Folders
}