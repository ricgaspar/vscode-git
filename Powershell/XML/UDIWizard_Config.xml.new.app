<?xml version="1.0" encoding="utf-8"?>
<Applications RootDisplayName="Applications">
  <ApplicationGroup Name="LijnPC / ProcessPC Software">
    <Application DisplayName="Apollo client 1.2" State="enabled" Id="1" Name="Apollo client" Guid="ScopeId_CBC73C04-210A-4CA3-A446-F90B3E0FC63A/Application_8e8e02f8-390e-4dd7-8d8a-7009c3fb78b2" Type="">
      <Setter Property="description" />
      <Dependencies />
      <Filters />
      <ApplicationMappings>
        <Match Type="WMI" OperatorCondition="OR" DisplayName="Apollo client">
          <Setter Property="Name">Apollo client</Setter>
        </Match>
        <Match Type="MSI" OperatorCondition="OR" DisplayName="Apollo client">
          <Setter Property="ProductId">{4A446FAD-0E2E-4D86-9C7C-2A0DDCCE23BC}</Setter>
        </Match>
      </ApplicationMappings>
    </Application>
    <Application DisplayName="ALC Apollo client 1.0" State="enabled" Id="2" Name="ALC Apollo client" Guid="ScopeId_CBC73C04-210A-4CA3-A446-F90B3E0FC63A/Application_fcb1d652-bcb0-45c8-9b53-a98662f6b040" Type="">
      <Setter Property="description" />
      <Dependencies />
      <Filters />
      <ApplicationMappings>
        <Match Type="WMI" OperatorCondition="OR" DisplayName="ALC Apollo client">
          <Setter Property="Name">ALC Apollo client</Setter>
        </Match>
        <Match Type="MSI" OperatorCondition="OR" DisplayName="ALC Apollo client">
          <Setter Property="ProductId">{AF8966A7-FD7D-46AF-82BA-DD9FCD47B9F6}</Setter>
        </Match>
      </ApplicationMappings>
    </Application>
    <Application DisplayName="Artemis Client 1.1.0" State="enabled" Id="5" Name="Artemis Client 1.1.0" Guid="ScopeId_CBC73C04-210A-4CA3-A446-F90B3E0FC63A/Application_15b68bfe-c9d1-44db-866d-f724face9299">
      <Setter Property="description" />
      <Dependencies />
      <Filters />
      <ApplicationMappings>
        <Match Type="WMI" OperatorCondition="OR" DisplayName="Artemis Client 1.1.0">
          <Setter Property="Name">Artemis Client 1.1.0</Setter>
        </Match>
        <Match Type="MSI" OperatorCondition="OR" DisplayName="Artemis Client 1.1.0">
          <Setter Property="ProductId">{FD001631-DA8C-4F11-9E86-048CA43618E7}</Setter>
        </Match>
      </ApplicationMappings>
    </Application>
    <Application DisplayName="Spatz Studio NET 2.7.2 for Bodyshop SPATZ PC" State="enabled" Id="3" Name="Spatz Studio NET 2.7.2" Guid="ScopeId_CBC73C04-210A-4CA3-A446-F90B3E0FC63A/Application_f2299ee0-4a1e-4b2b-b9f4-5600ca7658f8" Type="">
      <Setter Property="description" />
      <Dependencies />
      <Filters />
      <ApplicationMappings>
        <Match Type="WMI" OperatorCondition="OR" DisplayName="Spatz Studio NET 2.7.2">
          <Setter Property="Name">Spatz Studio NET 2.7.2</Setter>
        </Match>
        <Match Type="MSI" OperatorCondition="OR" DisplayName="Spatz Studio NET 2.7.2">
          <Setter Property="ProductId">
          </Setter>
        </Match>
      </ApplicationMappings>
    </Application>
  </ApplicationGroup>
  <SelectedApplications>
    <SelectApplication Application.Id="6" />
    <SelectApplication Application.Id="1" />
    <SelectApplication Application.Id="7" />
    <SelectApplication Application.Id="5" />
  </SelectedApplications>
  <ApplicationGroup Name="Active Directory based applications">
    <Application DisplayName="SCCM 2012 Remote Control Viewer" Name="SCCM 2012 Remote Control Viewer" Id="6" Guid="ScopeId_CBC73C04-210A-4CA3-A446-F90B3E0FC63A/Application_c0e29736-1333-4d7d-9689-eb6acd59bfa2">
      <Setter Property="description" />
      <Dependencies />
      <Filters />
      <ApplicationMappings>
        <Match Type="WMI" OperatorCondition="OR" DisplayName="SCCM 2012 Remote Control Viewer">
          <Setter Property="Name">SCCM 2012 Remote Control Viewer</Setter>
        </Match>
        <Match Type="MSI" OperatorCondition="OR" DisplayName="SCCM 2012 Remote Control Viewer">
          <Setter Property="ProductId">
          </Setter>
        </Match>
      </ApplicationMappings>
    </Application>
    <Application DisplayName="OpenText Imaging Viewer and DesktopLink 10.5.0" Name="OpenText Imaging Viewer and DesktopLink 10.5.0" Id="7" Guid="ScopeId_CBC73C04-210A-4CA3-A446-F90B3E0FC63A/Application_4c20265a-b5e7-4aeb-8919-5167ab3f6101">
      <Setter Property="description" />
      <Dependencies />
      <Filters />
      <ApplicationMappings>
        <Match Type="WMI" OperatorCondition="OR" DisplayName="OpenText Imaging Viewer and DesktopLink 10.5.0">
          <Setter Property="Name">OpenText Imaging Viewer and DesktopLink 10.5.0</Setter>
        </Match>
        <Match Type="MSI" OperatorCondition="OR" DisplayName="OpenText Imaging Viewer and DesktopLink 10.5.0">
          <Setter Property="ProductId">
          </Setter>
        </Match>
      </ApplicationMappings>
    </Application>
  </ApplicationGroup>
</Applications>