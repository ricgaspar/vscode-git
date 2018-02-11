function Get-FSMO
{
        
    <#
        .Synopsis 
            Returns the Flexible Single Master Operational roles.
            
        .Description
            Returns the Flexible Single Master Operational roles.
        
        .Parameter Role
            Gets a specific role. 
            Valid values: PDCMaster, RIDMaster, InfrastructureMaster, SchemaMaster, and DomainNamingMaster.
            
        .Parameter Domain
            Domain Controller to get the forest from.
        
        .Parameter Forest
            PSCredentials to use to discover forest with.
            
        .Example
            Get-FSMO
            Description
            -----------
            Returns all the FSMO roles for the current domain and forest.
            
        .Example
            Get-FSMO -role PDCMaster
            Description
            -----------
            Returns the PDCMaster FSMO role for the current domain.
            
        .Example
            Get-FSMO -Domain
            Description
            -----------
            Returns all the FSMO roles for the current domain.
            
        .Example
            Get-FSMO -Forest
            Description
            -----------
            Returns all the FSMO roles for the current forest.
            
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
            
        .Link
            Get-Forest
            Get-Domain
        
        .Notes
            NAME:      Get-FSMO
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding(DefaultParameterSetName="Role")]
    
    Param(
    
        [Parameter(ParameterSetName="Role",Position=0)]
        [ValidateSet("PDCMaster","RIDMaster","InfrastructureMaster","SchemaMaster","DomainNamingMaster")]
        [String]$Role,
        
        [Parameter(ParameterSetName="Domain",Position=0)]
        [switch]$Domain,
        
        [Parameter(ParameterSetName="Forest",Position=0)]
        [switch]$Forest
   
    )
    
    function New-FSMORole
    {
        Param($ComputerName,$Domain,$Role)
        $myobj = @{
            ComputerName  = $ComputerName
            Domain        = $Domain
            Role          = $Role
            NetBIOSName   = $ComputerName.Split(".")[0]
        }
        $obj = New-Object PSObject -Property $myobj
        $obj.PSTypeNames.Clear()
        $obj.PSTypeNames.Add('BSonPosh.ActiveDirectory.FSMORole')
        $obj
    }
    
    switch ($pscmdlet.ParameterSetName)
    {
        "Role"      {
                        $MyDomain = Get-Domain
                        $MyForest = Get-Forest
                        switch -exact ($Role)
                        {
                            "PDCMaster"                 {
                                                             New-FSMORole -ComputerName $MyDomain.PdcRoleOwner.ToString()  `
                                                                          -Domain $MyDomain.PdcRoleOwner.Domain.ToString() `
                                                                          -Role "PDCMaster"
                                                        }
                            "RIDMaster"                 {
                                                             New-FSMORole -ComputerName $MyDomain.RidRoleOwner.ToString()  `
                                                                          -Domain $MyDomain.RidRoleOwner.Domain.ToString() `
                                                                          -Role "RIDMaster"
                                                        }
                            "InfrastructureMaster"      {
                                                             New-FSMORole -ComputerName $MyDomain.InfrastructureRoleOwner.ToString()  `
                                                                          -Domain $MyDomain.InfrastructureRoleOwner.Domain.ToString() `
                                                                          -Role "InfrastructureMaster"
                                                        }
                            "SchemaMaster"              {
                                                             New-FSMORole -ComputerName $MyDomain.SchemaRoleOwner.ToString()  `
                                                                          -Domain $MyDomain.SchemaRoleOwner.Domain.ToString() `
                                                                          -Role "SchemaMaster"
                                                        }
                            "DomainNamingMaster"        {
                                                             New-FSMORole -ComputerName $MyDomain.NamingRoleOwner.ToString()  `
                                                                          -Domain $MyDomain.NamingRoleOwner.Domain.ToString() `
                                                                          -Role "DomainNamingMaster"
                                                        }
                            Default                     {
                                                            # Domain Roles
                                                            New-FSMORole -ComputerName $MyDomain.PdcRoleOwner.ToString()  `
                                                                        -Domain $MyDomain.PdcRoleOwner.Domain.ToString() `
                                                                        -Role "PDCMaster"
                                                            New-FSMORole -ComputerName $MyDomain.RidRoleOwner.ToString()  `
                                                                        -Domain $MyDomain.RidRoleOwner.Domain.ToString() `
                                                                        -Role "RIDMaster"
                                                            New-FSMORole -ComputerName $MyDomain.InfrastructureRoleOwner.ToString()  `
                                                                        -Domain $MyDomain.InfrastructureRoleOwner.Domain.ToString() `
                                                                        -Role "InfrastructureMaster"     
                                                                        
                                                            # Forest Roles
                                                            New-FSMORole -ComputerName $MyForest.SchemaRoleOwner.ToString()  `
                                                                        -Domain $MyForest.SchemaRoleOwner.Domain.ToString() `
                                                                        -Role "SchemaMaster"
                                                            New-FSMORole -ComputerName $MyForest.NamingRoleOwner.ToString()  `
                                                                        -Domain $MyForest.NamingRoleOwner.Domain.ToString() `
                                                                        -Role "DomainNamingMaster"
                                                        }   
                        }
                    }
                    
        "Domain"    {
                        $MyDomain = Get-Domain
                        # Domain Roles
                        New-FSMORole -ComputerName $MyDomain.PdcRoleOwner.ToString()  `
                                     -Domain $MyDomain.PdcRoleOwner.Domain.ToString() `
                                     -Role "PDCMaster"
                        New-FSMORole -ComputerName $MyDomain.RidRoleOwner.ToString()  `
                                     -Domain $MyDomain.RidRoleOwner.Domain.ToString() `
                                     -Role "RIDMaster"
                        New-FSMORole -ComputerName $MyDomain.InfrastructureRoleOwner.ToString()  `
                                     -Domain $MyDomain.InfrastructureRoleOwner.Domain.ToString() `
                                     -Role "InfrastructureMaster"  
                    }
                    
        "Forest"    {
                        $MyForest = Get-Forest
                        # Forest Roles
                        New-FSMORole -ComputerName $MyForest.SchemaRoleOwner.ToString()  `
                                     -Domain $MyForest.SchemaRoleOwner.Domain.ToString() `
                                     -Role "SchemaMaster"
                        New-FSMORole -ComputerName $MyForest.NamingRoleOwner.ToString()  `
                                     -Domain $MyForest.NamingRoleOwner.Domain.ToString() `
                                     -Role "DomainNamingMaster"
                    }
    }
}