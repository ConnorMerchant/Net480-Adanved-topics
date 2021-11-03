# Description : Utilitys for VM managment
#
# Creates a clone based on given inputs and also give the ability to delete VMs 
# Error reporting if something is wrong
#

#Credit
# Sam Johnson Helped very much with troubleshooting as well as helped explain issues I had 
# with passing variables between functions


function ConnectServer {
    
    if($conn = $global:DefaultVIServer){
    Write-Host "Connected" -ForegroundColor Green 
    }
    else {
        try{
            Connect-VIServer -Server vcenter.connor.local -ErrorAction Stop
            Write-Host "Connected"
        }
         catch {
             Write-Host "Cannot connect" -ForegroundColor Red
             exit
         }
    }

}


function GetDefaults ($file) {
    # Reads preset params from json file
    $preset = Get-Content $file | ConvertFrom-Json
    return $preset
    
}
function GetVM ($preset){
    $vm = $null
  #Get base VM
   $options = Get-VM 
    foreach($option in $options){
        Write-Host $option
    }
        
   $vmi = Read-Host -Prompt "What VM would you like as your base ?"
   if($vmi -eq ""){
    $vmi = $preset.basevm
    Write-Host $vmi
    }
    try {
       $vm = Get-VM -Name $vmi -ErrorAction Stop
        Write-Host "Valid VM Name"
    }
    catch {
        Write-Host "Invalid VM Name" -ForegroundColor Red
        GetVM
}
return $vm
return $vmi
}
function GetSnap ($vmi, $preset){
#Get Snapshot target
Write-Host $vmi 
$options = Get-Snapshot $vmi
foreach($option in $options){
    Write-Host $option
}
    
$snapshoti= Read-Host -Prompt " Select the snapshot you wish to use."
#$snapshot = Get-Snapshot -VM $vmi -Name $snapshoti -ErrorAction Stop
if ($snapshoti -eq "") {
    $snapshoti = $preset.snapshot
}
try {
    $snapshot = Get-Snapshot -VM $vmi -Name $snapshoti -ErrorAction Stop
    Write-Host "Valid Snapshot"
}
catch {
    Write-Host "Invalid Snapshot" -ForegroundColor Red

    GetSnap
}
return $snapshot    
}

function Gethost ($preset) {
#Get vmhost

$options = Get-VMHost
foreach($option in $options){
    Write-Host $option
}
$vmhosti = Read-Host -Prompt "What VMHost would you like to use?"
if ($vmhosti -eq ""){
    $vmhosti = $preset.VMHost
}
try{
    $vmhost = Get-VMHost -Name $vmhosti -ErrorAction Stop
    Write-Host "Valid Host"
}
catch {
    Write-Host "Invalid Host" -ForegroundColor Red
    Gethost
}

return $vmhost
}
function GetDS ($preset){
    $options = Get-Datastore  
    foreach($option in $options){
        Write-Host $option
    }
    $dsi = Read-Host -Prompt "Please enter the datastore you wish to use."
    if($dsi -eq ""){
       $dsi= $preset.datastore
    }
    try{
        $ds = Get-Datastore -Name $dsi -ErrorAction Stop
        Write-Host "Valid Datastore"
    }

catch {
        Write-Host "Invalid Datastore" -ForegroundColor Red
        GetDS
}
return $ds
}
function NewVMName {
    $NVMName = Read-Host -Prompt "What would you like to name the New VM?"
    return $NVMName
}
function GetVMType {
# Choose the Clone Type
$type = Read-Host -Prompt "For a Full clone enter [F] for a Linked clone enter [L]"

if ($type -eq "L"){
    $choice = "L"
}elseif ($type -eq "F") {
    $choice = "F"
}else {
    Write-Host "Invlaid Choice" -ForegroundColor Red
    Choose_Type
} 

return $choice
}

function FullClone ($vm, $vmi, $snapshot, $vmhost, $ds, $Name){
    $vm = $vm
    #Get Linked name
    $linkedname = "{0}.linked" -f $vm.Name
    #Create Linked VM
     Write-Host $vm   
    $linkedvm = New-VM -LinkedClone -Name $linkedname -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds
        
    #Create New VM
    try{
        New-VM -Name $Name -VM $linkedvm -VMHost $vmhost -Datastore $ds -ErrorAction Stop
        Write-Host "New VM created"
    }
    catch {
        Write-Host "Failed to create VM" -ForegroundColor Red
        FullClone
    }
    $del = Read-Host "Would you like to delete the temporary clone $linkedvm? [Y]/[N]"
    if ($del -eq "Y"){
        try {
            Remove-VM -VM $linkedvm -ErrorAction Stop
            Write-Host "Temp Clone Deleted"
        }
        catch {
            Write-Host "Could not delete clone. you can do so manually in Vcenter" -ForegroundColor Red
        }
    }
    else {
        Write-Host "It is advised to delete the temp clone manually in vcenter"
    }  
    
}
function LinkedClone ($vm, $snapshot, $vmhost, $ds, $Name){

   try {New-VM -LinkedClone -Name $Name -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds -ErrorAction Stop
       Write-Host "Linked Clone Created" 
       

    }
  catch {
    Write-Host "Could not create Linked clone" -ForegroundColor Red
    
    }
}

function NWadapter ($vm,$network,$esxi,$vcenter){
    
    ConnectServer
    $preset = GetDefaults -file vars.json
    $options = Get-NetworkAdapter -VM $vm
    Write-Host $options
    $adapter = Read-Host "Select adapter"
    if ($adapter -eq ""){
    $adapter = $preset.adapter
    }
    try{ $adapter = Get-NetworkAdapter -VM $vm -Name $adapter -ErrorAction Stop
    }
    catch { Write-Host "not a valid choice"
        NWadapter -vm $vm -preset $preset    
    }
    try {
        Get-NetworkAdapter -VM $vm -Name $adapter| Set-NetworkAdapter -NetworkName $network -Confirm:$false -ErrorAction Stop
        Write-Host "$adapter has been switch to network named $network"
    }
    catch {
        Write-Host "Invalid network name " -ForegroundColor Red
        exit
    } 
    $again = Read-Host -Prompt "Would you like to change another adapter? [Y/N]"
    if($again -eq "Y"){
        $options = Get-NetworkAdapter -VM $vm
    Write-Host $options
    $adapter = Read-Host "Select adapter"
    if ($adapter -eq ""){
    $adapter = $preset.adapter
    }
    try{ $adapter = Get-NetworkAdapter -VM $vm -Name $adapter -ErrorAction Stop
    }
    catch { Write-Host "not a valid choice"
        NWadapter -vm $vm -preset $preset    
    }
    try {
        Get-NetworkAdapter -VM $vm -Name $adapter| Set-NetworkAdapter -NetworkName Bluewan -Confirm:$false -ErrorAction Stop
        Write-Host "$adapter has been switch to network named $network"
    }
    catch {
        Write-Host "Invalid network name " -ForegroundColor Red
        exit
    }
    }
    else {
       Write-Host "exiting"
    }
      
}

function CreateNetwork ($name, $esxi, $server){
    ConnectServer
    try{
        $switch = New-VirtualSwitch -VMHost $esxi -Name $name
        New-VirtualPortGroup -Name $name -VLanId 0 -VirtualSwitch $switch
    }
    catch{
        Write-Host "Invalind inputs new network not created"
        exit
    }
}
function getIP ($name){
    
    ConnectServer
    $vm = Get-VM -Name $name
    $ip = $vm.guest.IPAddress[0]
    $hostname = $vm.guest.VmName
    $form = "$ip hostname=$hostname"

    Write-Host $form
}


function PowerVM ($VMName){

    start-VM -VM $VMName 
    
}
function Creation {


    ConnectServer
    $preset = GetDefaults -file vars.json
    $vm = GetVM -preset $preset
    $snapshot = GetSnap -vmi $vm -preset $preset
    $vmhost = Gethost -preset $preset
    $ds = GetDS -preset $preset
    $NVMName = NewVMName
    $choice = GetVMType
    if($choice -eq "L"){
        LinkedClone -Name $NVMName -vm $vm -VMHost $vmhost -ds $ds -snapshot $snapshot
    }
    elseif ($choice -eq "F"){
        FullClone -Name $NVMName -vm $vm -VMHost $vmhost -ds $ds -snapshot $snapshot
        
    }
    $power = Read-Host -Prompt "Do you want to start the new VM? [Y]/[N]"
    if ($power -eq "Y"){
        PowerVM -VMName $NVMName
        Write-Host "The VM has been created and is powered on" -ForegroundColor Green
    }
    else {
        Write-Host "The VM has been created and is not powered on"
    }
        
    }



#Creating a new Network for Blue1-wan
#createNetwork - networkname "Blue2-WAN" -esxi_host_name "super2.cyber.local" -vcenter_server
#