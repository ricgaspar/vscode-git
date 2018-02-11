#Generated Form Function
function executeSCCMAction ([string]$srv, [string]$action, $fscheduleID){

   #Binding SMS_Client wmi class remotely.... 
   $SMSCli = [wmiclass] "\\$srv\root\ccm:SMS_Client"

   if($SMSCli){
      if($action -imatch "full"){
         #Clearing HW or SW inventory delta flag...
         $wmiQuery = "\\$srv\root\ccm\invagt:InventoryActionStatus.InventoryActionID=$fscheduleID"
         $checkdelete = ([wmi]$wmiQuery).Delete()
      }   
      #Invoking $action ...
      $statusBar1.Text="$srv, Invoking action $script:actionName"
      $check = $SMSCli.TriggerSchedule($fscheduleID)
   }
   else{
      # could not get SCCM WMI Class
      $statusBar1.Text="$srv, could not get SCCM WMI Class"
   }
}
function GenerateForm {

#region Import the Assemblies
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
#endregion

#region Generated Form Objects
$form1 = New-Object System.Windows.Forms.Form
$ExecuteBtn = New-Object System.Windows.Forms.Button
$comboBox1 = New-Object System.Windows.Forms.ComboBox
$ActionLabel = New-Object System.Windows.Forms.Label
$statusBar1 = New-Object System.Windows.Forms.StatusBar
$TargetComp = New-Object System.Windows.Forms.TextBox
$TargetLabel = New-Object System.Windows.Forms.Label
$openFileDialog1 = New-Object System.Windows.Forms.OpenFileDialog
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
#endregion Generated Form Objects

#----------------------------------------------
#Event Script Blocks
#----------------------------------------------

$ExecuteBtn_OnClick= 
{

if ($comboBox1.text -eq "Hardware Inventory Cycle (Delta)") {
 $scheduleID = "{00000000-0000-0000-0000-000000000001}"
      $script:actionName = $comboBox1.text
	  }
	  if ($comboBox1.text -eq "Hardware Inventory Cycle (Full)") {
 $scheduleID = "{00000000-0000-0000-0000-000000000001}"
      $script:actionName = $comboBox1.text
	  }
	  if ($comboBox1.text -eq "Software Inventory Cycle (Delta)") {
 $scheduleID = "{00000000-0000-0000-0000-000000000002}"
      $script:actionName = $comboBox1.text
	  }
	  if ($comboBox1.text -eq "Software Inventory Cycle (Full)") {
 $scheduleID = "{00000000-0000-0000-0000-000000000002}"
      $script:actionName = $comboBox1.text
	  }
	  if ($comboBox1.text -eq "Discovery Data Collection Cycle (Delta)") {
 $scheduleID = "{00000000-0000-0000-0000-000000000003}"
      $script:actionName = $comboBox1.text
	  }
	  if ($comboBox1.text -eq "Discovery Data Collection Cycle (Full)") {
 $scheduleID = "{00000000-0000-0000-0000-000000000003}"
      $script:actionName = $comboBox1.text
	  }
	  if ($comboBox1.text -eq "File Collection Cycle (Delta)") {
 $scheduleID = "{00000000-0000-0000-0000-000000000010}"
      $script:actionName = $comboBox1.text
	  }
	  if ($comboBox1.text -eq "File Collection Cycle (Full)") {
 $scheduleID = "{00000000-0000-0000-0000-000000000010}"
      $script:actionName = $comboBox1.text
	  }
	  if ($comboBox1.text -eq "Software Updates Deployment Evaluation Cycle") {
 $scheduleID = "{00000000-0000-0000-0000-000000000108}"
      $script:actionName = $comboBox1.text
	  }
if ($comboBox1.text -eq "Software Updates Scan Cycle") {
 $scheduleID = "{00000000-0000-0000-0000-000000000113}"
      $script:actionName = $comboBox1.text
	  }


$srv=$TargetComp.text
$statusBar1.Text="Executing Action "+$action+" on  "+$srv
      if($srv){
         executeSCCMAction $srv $action $scheduleID 
      }else{
   # No hostname or hostlist is specified
    }
}
	  
$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
	$form1.WindowState = $InitialFormWindowState
}

#----------------------------------------------
#region Form Code
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 119
$System_Drawing_Size.Width = 409
$form1.ClientSize = $System_Drawing_Size
$form1.DataBindings.DefaultDataSourceUpdateMode = 0
$form1.Name = "form1"
$form1.ShowIcon = $False
$form1.Text = "SCCM Client Control Tool"


$ExecuteBtn.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 311
$System_Drawing_Point.Y = 49
$ExecuteBtn.Location = $System_Drawing_Point
$ExecuteBtn.Name = "ExecuteBtn"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 75
$ExecuteBtn.Size = $System_Drawing_Size
$ExecuteBtn.TabIndex = 20
$ExecuteBtn.Text = "Execute"
$ExecuteBtn.UseVisualStyleBackColor = $True
$ExecuteBtn.add_Click($ExecuteBtn_OnClick)

$form1.Controls.Add($ExecuteBtn)

$comboBox1.DataBindings.DefaultDataSourceUpdateMode = 0
$comboBox1.FormattingEnabled = $True
$comboBox1.Items.Add("Hardware Inventory Cycle (Delta)")|Out-Null
$comboBox1.Items.Add("Hardware Inventory Cycle (Full)")|Out-Null
$comboBox1.Items.Add("Software Inventory Cycle (Delta)")|Out-Null
$comboBox1.Items.Add("Software Inventory Cycle (Full)")|Out-Null
$comboBox1.Items.Add("Discovery Data Collection Cycle (Delta)")|Out-Null
$comboBox1.Items.Add("Discovery Data Collection Cycle (Full)")|Out-Null
$comboBox1.Items.Add("File Collection Cycle (Delta)")|Out-Null
$comboBox1.Items.Add("File Collection Cycle (Full)")|Out-Null
$comboBox1.Items.Add("Software Updates Deployment Evaluation Cycle")|Out-Null
$comboBox1.Items.Add("Software Updates Scan Cycle")|Out-Null
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 107
$System_Drawing_Point.Y = 49
$comboBox1.Location = $System_Drawing_Point
$comboBox1.Name = "comboBox1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 21
$System_Drawing_Size.Width = 198
$comboBox1.Size = $System_Drawing_Size
$comboBox1.TabIndex = 19

$form1.Controls.Add($comboBox1)

$ActionLabel.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 13
$System_Drawing_Point.Y = 49
$ActionLabel.Location = $System_Drawing_Point
$ActionLabel.Name = "ActionLabel"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 87
$ActionLabel.Size = $System_Drawing_Size
$ActionLabel.TabIndex = 18
$ActionLabel.Text = "Select Action"

$form1.Controls.Add($ActionLabel)

$statusBar1.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 0
$System_Drawing_Point.Y = 97
$statusBar1.Location = $System_Drawing_Point
$statusBar1.Name = "statusBar1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 22
$System_Drawing_Size.Width = 409
$statusBar1.Size = $System_Drawing_Size
$statusBar1.TabIndex = 8
$statusBar1.Text = "statusBar1"

$form1.Controls.Add($statusBar1)

$TargetComp.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 107
$System_Drawing_Point.Y = 26
$TargetComp.Location = $System_Drawing_Point
$TargetComp.Name = "TargetComp"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 20
$System_Drawing_Size.Width = 198
$TargetComp.Size = $System_Drawing_Size
$TargetComp.TabIndex = 1

$form1.Controls.Add($TargetComp)

$TargetLabel.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 13
$System_Drawing_Point.Y = 26
$TargetLabel.Location = $System_Drawing_Point
$TargetLabel.Name = "TargetLabel"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 96
$TargetLabel.Size = $System_Drawing_Size
$TargetLabel.TabIndex = 0
$TargetLabel.Text = "Target Computer"
$TargetLabel.add_Click($handler_label8_Click)

$form1.Controls.Add($TargetLabel)

$openFileDialog1.FileName = "openFileDialog1"
$openFileDialog1.ShowHelp = $True
$openFileDialog1.add_FileOk($handler_openFileDialog1_FileOk)

#endregion Form Code

#Save the initial state of the form
$InitialFormWindowState = $form1.WindowState
#Init the OnLoad event to correct the initial state of the form
$form1.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$statusBar1.Text="Ready"
$form1.ShowDialog()| Out-Null

} #End Function

#Call the Function
GenerateForm