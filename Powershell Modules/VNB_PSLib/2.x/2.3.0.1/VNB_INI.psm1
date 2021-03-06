<#
.SYNOPSIS
    VNB Library - INI files

.CREATED_BY
	Marcel Jussen

.VERSION
	2.3.0.1

.CHANGE_DATE
	20-11-2017

.DESCRIPTION
    Functions to read and write INI file contents.
#>
#Requires -version 4.0

Function Get-IniContent
{
    # ---------------------------------------------------------
    #
    # ---------------------------------------------------------
    <#
    .Synopsis
        Gets the content of an INI file

    .Description
        Gets the content of an INI file and returns it as a hashtable

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Date      : 2014/06/23
        Version   : 1.1

        #Requires -Version 2.0

    .Inputs
        System.String

    .Outputs
        System.Collections.Hashtable

    .Parameter FilePath
        Specifies the path to the input file.

    .Example
        $FileContent = Get-IniContent "C:\myinifile.ini"
        -----------
        Description
        Saves the content of the c:\myinifile.ini in a hashtable called $FileContent

    .Example
        $inifilepath | $FileContent = Get-IniContent
        -----------
        Description
        Gets the content of the ini file passed through the pipe into a hashtable called $FileContent

    .Example
        C:\PS>$FileContent = Get-IniContent "c:\settings.ini"
        C:\PS>$FileContent["Section"]["Key"]
        -----------
        Description
        Returns the key "Key" of the section "Section" from the C:\settings.ini file

    .Link
        Out-IniFile
    #>

    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]
        [Parameter(ValueFromPipeline = $True, Mandatory = $True)]
        [string]$FilePath
    )

    Begin
    {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"

        $ini = @{}
        switch -regex -file $FilePath
        {
            "^\[(.+)\]$" # Section
            {
                $section = $matches[1]
                $ini[$section] = @{}
                $CommentCount = 0
            }
            "^(;.*)$" # Comment
            {
                if (!($section))
                {
                    $section = "No-Section"
                    $ini[$section] = @{}
                }
                $value = $matches[1]
                $CommentCount = $CommentCount + 1
                $name = "Comment" + $CommentCount
                $ini[$section][$name] = $value
            }
            "(.+?)\s*=\s*(.*)" # Key
            {
                if (!($section))
                {
                    $section = "No-Section"
                    $ini[$section] = @{}
                }
                $name, $value = $matches[1..2]
                $ini[$section][$name] = $value
            }
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $path"
        Return $ini
    }

    End
    {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}
Set-Alias Read-INIFile Get-IniContent
Set-Alias Get-INIFile Get-IniContent


Function Out-IniFile
{
    # ---------------------------------------------------------
    #
    # ---------------------------------------------------------
    <#
    .Synopsis
        Write hash content to INI file

    .Description
        Write hash content to INI file

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog       : http://oliver.lipkau.net/blog/
        Version   : 1.0 - 2010/03/12 - Initial release
                       1.1 - 2012-04-19 - Bugfix/Added example to help (Thx Ingmar Verheij)

        #Requires -Version 2.0

    .Inputs
        System.String
        System.Collections.Hashtable

    .Outputs
        System.IO.FileSystemInfo

    .Parameter Append
        Adds the output to the end of an existing file, instead of replacing the file contents.

    .Parameter InputObject
        Specifies the Hashtable to be written to the file. Enter a variable that contains the objects or type a command or expression that gets the objects.

    .Parameter FilePath
        Specifies the path to the output file.

     .Parameter Encoding
        Specifies the type of character encoding used in the file. Valid values are "Unicode", "UTF7",
         "UTF8", "UTF32", "ASCII", "BigEndianUnicode", "Default", and "OEM". "Unicode" is the default.

        "Default" uses the encoding of the system's current ANSI code page.

        "OEM" uses the current original equipment manufacturer code page identifier for the operating
        system.

     .Parameter Force
        Allows the cmdlet to overwrite an existing read-only file. Even using the Force parameter, the cmdlet cannot override security restrictions.

     .Parameter PassThru
        Passes an object representing the location to the pipeline. By default, this cmdlet does not generate any output.

    .Example
        Out-IniFile $IniVar "C:\myinifile.ini"
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini

    .Example
        $IniVar | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and overwrites the file if it is already present

    .Example
        $file = Out-IniFile $IniVar "C:\myinifile.ini" -PassThru
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and saves the file into $file

    .Example
        $Category1 = @{“Key1”=”Value1”;”Key2”=”Value2”}
    $Category2 = @{“Key1”=”Value1”;”Key2”=”Value2”}
    $NewINIContent = @{“Category1”=$Category1;”Category2”=$Category2}
    Out-IniFile -InputObject $NewINIContent -FilePath "C:\MyNewFile.INI"
        -----------
        Description
        Creating a custom Hashtable and saving it to C:\MyNewFile.INI
    .Link
        Get-IniContent
    #>

    [CmdletBinding()]
    Param(
        [switch]$Append,

        [ValidateSet("Unicode", "UTF7", "UTF8", "UTF32", "ASCII", "BigEndianUnicode", "Default", "OEM")]
        [Parameter()]
        [string]$Encoding = "Unicode",

        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^([a-zA-Z]\:)?.+\.ini$')]
        [Parameter(Mandatory = $True)]
        [string]$FilePath,

        [switch]$Force,

        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $True, Mandatory = $True)]
        [Hashtable]$InputObject,

        [switch]$Passthru
    )

    Begin
    {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing to file: $Filepath"

        if ($append) {$outfile = Get-Item $FilePath}
        else {$outFile = New-Item -ItemType file -Path $Filepath -Force:$Force}
        foreach ($i in $InputObject.keys)
        {
            if (!($($InputObject[$i].GetType().Name) -eq "Hashtable"))
            {
                #No Sections
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $i"
                Add-Content -Path $outFile -Value "$i=$($InputObject[$i])" -Encoding $Encoding
            }
            else
            {
                #Sections
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing Section: [$i]"
                Add-Content -Path $outFile -Value "[$i]" -Encoding $Encoding
                Foreach ($j in $($InputObject[$i].keys | Sort-Object))
                {
                    if ($j -match "^Comment[\d]+")
                    {
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing comment: $j"
                        Add-Content -Path $outFile -Value "$($InputObject[$i][$j])" -Encoding $Encoding
                    }
                    else
                    {
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $j"
                        Add-Content -Path $outFile -Value "$j=$($InputObject[$i][$j])" -Encoding $Encoding
                    }

                }
                Add-Content -Path $outFile -Value "" -Encoding $Encoding
            }
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Writing to file: $path"
        if ($PassThru) {Return $outFile}
    }

    End
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}
Set-Alias Write-INIFile Out-IniFile
Set-Alias Set-INIFile Out-IniFile

function Split-Ini
{
    <#
    .SYNOPSIS
    Reads an INI file and returns its contents.

    .DESCRIPTION
    A configuration file consists of sections, led by a "[section]" header and followed by "name = value" entries:

        [spam]
        eggs=ham
        green=
           eggs

        [stars]
        sneetches = belly

    By default, the INI file will be returned as `Carbon.Ini.IniNode` objects for each name/value pair.  For example, given the INI file above, the following will be returned:

        Line FullName        Section Name      Value
        ---- --------        ------- ----      -----
           2 spam.eggs       spam    eggs      ham
           3 spam.green      spam    green     eggs
           7 stars.sneetches stars   sneetches belly

    It is sometimes useful to get a hashtable back of the name/values.  The `AsHashtable` switch will return a hashtable where the keys are the full names of the name/value pairs.  For example, given the INI file above, the following hashtable is returned:

        Name            Value
        ----            -----
        spam.eggs       Carbon.Ini.IniNode;
        spam.green      Carbon.Ini.IniNode;
        stars.sneetches Carbon.Ini.IniNode;
        }

    Each line of an INI file contains one entry. If the lines that follow are indented, they are treated as continuations of that entry. Leading whitespace is removed from values. Empty lines are skipped. Lines beginning with "#" or ";" are ignored and may be used to provide comments.

    Configuration keys can be set multiple times, in which case Split-Ini will use the value that was configured last. As an example:

        [spam]
        eggs=large
        ham=serrano
        eggs=small

    This would set the configuration key named "eggs" to "small".

    It is also possible to define a section multiple times. For example:

        [foo]
        eggs=large
        ham=serrano
        eggs=small

        [bar]
        eggs=ham
        green=
           eggs

        [foo]
        ham=prosciutto
        eggs=medium
        bread=toasted

    This would set the "eggs", "ham", and "bread" configuration keys of the "foo" section to "medium", "prosciutto", and "toasted", respectively. As you can see, the only thing that matters is the last value that was set for each of the configuration keys.

    Be default, operates on the INI file case-insensitively. If your INI is case-sensitive, use the `-CaseSensitive` switch.

    .LINK
    Set-IniEntry

    .LINK
    Remove-IniEntry

    .EXAMPLE
    Split-Ini -Path C:\Users\rspektor\mercurial.ini

    Given this INI file:

        [ui]
        username = Regina Spektor <regina@reginaspektor.com>

        [extensions]
        share =
        extdiff =

    `Split-Ini` returns the following objects to the pipeline:

        Line FullName           Section    Name     Value
        ---- --------           -------    ----     -----
           2 ui.username        ui         username Regina Spektor <regina@reginaspektor.com>
           5 extensions.share   extensions share
           6 extensions.extdiff extensions extdiff

    .EXAMPLE
    Split-Ini -Path C:\Users\rspektor\mercurial.ini -AsHashtable

    Given this INI file:

        [ui]
        username = Regina Spektor <regina@reginaspektor.com>

        [extensions]
        share =
        extdiff =

    `Split-Ini` returns the following hashtable:

        @{
            ui.username = Carbon.Ini.IniNode (
                                FullName = 'ui.username';
                                Section = "ui";
                                Name = "username";
                                Value = "Regina Spektor <regina@reginaspektor.com>";
                                LineNumber = 2;
                            );
            extensions.share = Carbon.Ini.IniNode (
                                    FullName = 'extensions.share';
                                    Section = "extensions";
                                    Name = "share"
                                    Value = "";
                                    LineNumber = 5;
                                )
            extensions.extdiff = Carbon.Ini.IniNode (
                                       FullName = 'extensions.extdiff';
                                       Section = "extensions";
                                       Name = "extdiff";
                                       Value = "";
                                       LineNumber = 6;
                                  )
        }

    .EXAMPLE
    Split-Ini -Path C:\Users\rspektor\mercurial.ini -AsHashtable -CaseSensitive

    Demonstrates how to parse a case-sensitive INI file.

        Given this INI file:

        [ui]
        username = user@example.com
        USERNAME = user2example.com

        [UI]
        username = user3@example.com


    `Split-Ini -CaseSensitive` returns the following hashtable:

        @{
            ui.username = Carbon.Ini.IniNode (
                                FullName = 'ui.username';
                                Section = "ui";
                                Name = "username";
                                Value = "user@example.com";
                                LineNumber = 2;
                            );
            ui.USERNAME = Carbon.Ini.IniNode (
                                FullName = 'ui.USERNAME';
                                Section = "ui";
                                Name = "USERNAME";
                                Value = "user2@example.com";
                                LineNumber = 3;
                            );
            UI.username = Carbon.Ini.IniNode (
                                FullName = 'UI.username';
                                Section = "UI";
                                Name = "username";
                                Value = "user3@example.com";
                                LineNumber = 6;
                            );
        }

    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath')]
        [string]
        # The path to the mercurial INI file to read.
        $Path,

        [Switch]
        # Pass each parsed setting down the pipeline instead of collecting them all into a hashtable.
        $AsHashtable,

        [Switch]
        # Parses the INI file in a case-sensitive manner.
        $CaseSensitive
    )

    if ( -not (Test-Path $Path -PathType Leaf) )
    {
        Write-Error ("INI file '{0}' not found." -f $Path)
        return
    }

    $sectionName = ''
    $lineNum = 0
    $lastSetting = $null
    $settings = @{ }
    if ( $CaseSensitive )
    {
        $settings = New-Object 'Collections.Hashtable'
    }

    Get-Content -Path $Path | ForEach-Object {

        $lineNum += 1

        if ( -not $_ -or $_ -match '^[;#]' )
        {
            if ( -not $AsHashtable -and $lastSetting )
            {
                $lastSetting
            }
            $lastSetting = $null
            return
        }

        if ( $_ -match '^\[([^\]]+)\]' )
        {
            if ( -not $AsHashtable -and $lastSetting )
            {
                $lastSetting
            }
            $lastSetting = $null
            $sectionName = $matches[1]
            Write-Verbose "Parsed section [$sectionName]"
            return
        }

        if ( $_ -match '^\s+(.*)$' -and $lastSetting )
        {
            $lastSetting.Value += "`n" + $matches[1]
            return
        }

        if ( $_ -match '^([^=]*) ?= ?(.*)$' )
        {
            if ( -not $AsHashtable -and $lastSetting )
            {
                $lastSetting
            }

            $name = $matches[1]
            $value = $matches[2]

            $name = $name.Trim()
            $value = $value.TrimStart()

            $setting = New-Object Carbon.Ini.IniNode $sectionName, $name, $value, $lineNum
            $settings[$setting.FullName] = $setting
            $lastSetting = $setting
            Write-Verbose "Parsed setting '$($setting.FullName)'"
        }
    }

    if ( $AsHashtable )
    {
        return $settings
    }
    else
    {
        if ( $lastSetting )
        {
            $lastSetting
        }
    }
}

function Set-IniEntry
{
    <#
    .SYNOPSIS
    Sets an entry in an INI file.

    .DESCRIPTION
    A configuration file consists of sections, led by a `[section]` header and followed by `name = value` entries.  This function creates or updates an entry in an INI file.  Something like this:

        [ui]
        username = Regina Spektor <regina@reginaspektor.com>

        [extensions]
        share =
        extdiff =

    Names are not allowed to contains the equal sign, `=`.  Values can contain any character.  The INI file is parsed using `Split-Ini`.  [See its documentation for more examples.](Split-Ini.html)

    Be default, operates on the INI file case-insensitively. If your INI is case-sensitive, use the `-CaseSensitive` switch.

    .LINK
    Split-Ini

    LINK
    Remove-IniEntry

    .EXAMPLE
    Set-IniEntry -Path C:\Users\rspektor\mercurial.ini -Section extensions -Name share -Value ''

    If the `C:\Users\rspektor\mercurial.ini` file is empty, adds the following to it:

        [extensions]
        share =

    .EXAMPLE
    Set-IniEntry -Path C:\Users\rspektor\music.ini -Name genres -Value 'alternative,rock'

    If the `music.ini` file is empty, adds the following to it:

        genres = alternative,rock

    .EXAMPLE
    Set-IniEntry -Path C:\Users\rspektor\music.ini -Name genres -Value 'alternative,rock,world'

    If the `music.ini` file contains the following:

        genres = r&b

    After running this command, `music.ini` will look like this:

        genres = alternative,rock,world

    .EXAMPLE
    Set-IniEntry -Path C:\users\me\npmrc -Name prefix -Value 'C:\Users\me\npm_modules' -CaseSensitive

    Demonstrates how to set an INI entry in a case-sensitive file.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The path to the INI file to set.
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        # The name of the INI entry being set.
        $Name,

        [string]
        # The value of the INI entry being set.
        $Value,

        [string]
        # The section of the INI where the entry should be set.
        $Section,

        [Switch]
        # Treat the INI file in a case-sensitive manner.
        $CaseSensitive
    )

    Set-StrictMode -Version 'Latest'

    if ( $Name -like '*=*' )
    {
        Write-Error "INI entry name '$Name' invalid: can not contain equal sign '='."
        return
    }


    $settings = @{ }
    $lines = New-Object 'Collections.ArrayList'

    if ( Test-Path $Path -PathType Leaf )
    {
        $settings = Split-Ini -Path $Path -AsHashtable -CaseSensitive:$CaseSensitive
        Get-Content -Path $Path | ForEach-Object { [void] $lines.Add( $_ ) }
    }

    $settings.Values |
        Add-Member -MemberType NoteProperty -Name 'Updated' -Value $false -PassThru |
        Add-Member -MemberType NoteProperty -Name 'IsNew' -Value $false

    $key = "$Name"
    if ( $Section )
    {
        $key = "$Section.$Name"
    }

    if ( $settings.ContainsKey( $key ) )
    {
        $setting = $settings[$key]
        if ( $setting.Value -cne $Value )
        {
            Write-Verbose -Message "Updating INI entry '$key' in '$Path'."
            $lines[$setting.LineNumber - 1] = "$Name = $Value"
        }
    }
    else
    {
        $lastItemInSection = $settings.Values | `
            Where-Object { $_.Section -eq $Section } | `
            Sort-Object -Property LineNumber | `
            Select-Object -Last 1

        $newLine = "$Name = $Value"
        Write-Verbose -Message "Creating INI entry '$key' in '$Path'."
        if ( $lastItemInSection )
        {
            $idx = $lastItemInSection.LineNumber
            $lines.Insert( $idx, $newLine )
            if ( $lines.Count -gt ($idx + 1) -and $lines[$idx + 1])
            {
                $lines.Insert( $idx + 1, '' )
            }
        }
        else
        {
            if ( $Section )
            {
                if ( $lines.Count -gt 1 -and $lines[$lines.Count - 1] )
                {
                    [void] $lines.Add( '' )
                }
                [void] $lines.Add( "[$Section]" )
                [void] $lines.Add( $newLine )
            }
            else
            {
                $lines.Insert( 0, $newLine )
                if ( $lines.Count -gt 1 -and $lines[1] )
                {
                    $lines.Insert( 1, '' )
                }
            }
        }
    }

    $lines | Out-File -FilePath $Path -Encoding OEM
}

function Remove-IniEntry
{
    <#
    .SYNOPSIS
    Removes an entry/line/setting from an INI file.

    .DESCRIPTION
    A configuration file consists of sections, led by a `[section]` header and followed by `name = value` entries.  This function removes an entry in an INI file.  Something like this:

        [ui]
        username = Regina Spektor <regina@reginaspektor.com>

        [extensions]
        share =
        extdiff =

    Names are not allowed to contains the equal sign, `=`.  Values can contain any character.  The INI file is parsed using `Split-Ini`.  [See its documentation for more examples.](Split-Ini.html)

    If the entry doesn't exist, does nothing.

    Be default, operates on the INI file case-insensitively. If your INI is case-sensitive, use the `-CaseSensitive` switch.

    .LINK
    Set-IniEntry

    .LINK
    Split-Ini

    .EXAMPLE
    Remove-IniEntry -Path C:\Projects\Carbon\StupidStupid.ini -Section rat -Name tails

    Removes the `tails` item in the `[rat]` section of the `C:\Projects\Carbon\StupidStupid.ini` file.

    .EXAMPLE
    Remove-IniEntry -Path C:\Users\me\npmrc -Name 'prefix' -CaseSensitive

    Demonstrates how to remove an INI entry in an INI file that is case-sensitive.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        # The path to the INI file.
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        # The name of the INI entry to remove.
        $Name,

        [string]
        # The section of the INI where the entry should be set.
        $Section,

        [Switch]
        # Removes INI entries in a case-sensitive manner.
        $CaseSensitive
    )

    Set-StrictMode -Version 'Latest'

    $settings = @{ }

    if ( Test-Path $Path -PathType Leaf )
    {
        $settings = Split-Ini -Path $Path -AsHashtable -CaseSensitive:$CaseSensitive
    }
    else
    {
        Write-Error ('INI file {0} not found.' -f $Path)
        return
    }

    $key = $Name
    if ( $Section )
    {
        $key = '{0}.{1}' -f $Section, $Name
    }

    if ( $settings.ContainsKey( $key ) )
    {
        $lines = New-Object 'Collections.ArrayList'
        Get-Content -Path $Path | ForEach-Object { [void] $lines.Add( $_ ) }
        $null = $lines.RemoveAt( ($settings[$key].LineNumber - 1) )
        if ( $PSCmdlet.ShouldProcess( $Path, ('remove INI entry {0}' -f $key) ) )
        {
            $lines | Out-File -FilePath $Path -Encoding OEM
        }
    }

}

# ---------------------------------------------------------
# Export aliases
# ---------------------------------------------------------
export-modulemember -alias * -function *