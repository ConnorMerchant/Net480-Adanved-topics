# Description : Utilitys for VM managment
#
# Creates a clone based on given inputs and also give the ability to delete VMs 
# Error reporting if something is wrong



function ConnectServer {
try{
    Connect-VIServer -Server vcenter.connor.local -ErrorAction Stop
    Write-Host "Connected"
}
 catch {
     Write-Host "Cannot connect" -ForegroundColor Red
     exit
 }
}

function GetVM {
  #Get base VM
   $options = Get-VM 
    foreach($option in $options){
        Write-Host $option
    }
        
   $vmi = Read-Host -Prompt "What VM would you like as your base ?"
   $vm = Get-VM -Name $vmi
    try {
        Get-VM -Name $vmi -ErrorAction Stop
        Write-Host "Valid VM Name"
    }
    catch {
        Write-Host "Invalid VM Name" -ForegroundColor Red
        GetVM
}
return $vm
}
function GetSnap ($vmi){
#Get Snapshot target

$options = Get-Snapshot $vmi
foreach($option in $options){
    Write-Host $option
}
    
$snapshoti= Read-Host -Prompt " Select the snapshot you wish to use."
$snapshot = Get-Snapshot -VM $vmi -Name $snapshoti -ErrorAction Stop

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
function Gethost {
#Get vmhost

Get-VMHost
$vmhosti = Read-Host -Prompt "What VMHost would you like to use?"
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
function GetDS {
    Get-Datastore
    $dsi = Read-Host -Prompt "Please enter the datastore you wish to use."
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
    $choice = "Linked"
}elseif ($type -eq "F") {
    $choice = "Full"
}else {
    Write-Host "Invlaid Choice" -ForegroundColor Red
    Choose_Type
} 

return $choice
}

function FullClone ($vm, $snapshot, $vmhost, $ds, $NVMName){
    
    #Get Linked name
    $linkedname = "{0}.linked" -f $vm.name
    #Create Linked VM
        
    $linkedvm = New-VM -LinkedClone -Name $linkedname -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds
        
    #Create New VM
    try{
        New-VM -Name $NVMName -VM $linkedvm -VMHost $vmhost -Datastore $ds -ErrorAction Stop
        Write-Host "New VM created"
    }
    catch {
        Write-Host "Failed to create VM" -ForegroundColor Red
        FullClone
    }
    $del = Read-Host "Would you like to delete the temporary clone $linkedvm? [Y]/[N]"
    if ($del -eq "Y"){
        try {
            Remove-VM -Name $linkedvm -ErrorAction Stop
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
function LinkedClone ($vm, $snapshot, $vmhost, $ds, $NVMName){
    try {New-VM -LinkedClone -Name $NVMName -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds -ErrorAction Stop
        Write-Host "Linked Clone Created" 

    }
catch {
    Write-Host "Could not create Linked clone" -ForegroundColor Red
    LinkedClone
}
}
function Creation {
    ConnectServer
    Write-Host "Welcome to the Clone creator"
    $vm = GetVM
    $snapshot = GetSnap -vmi $vm
    $vmhost = Gethost
    $ds = GetDS
    $NVMName = NewVMName
    $choice = GetVMType
    if($choice -eq "L"){
        LinkedClone -name $NVMName -vm $vm -VMHost $vmhost -data $ds -ReferenceSnapshot $snap
    }
    elseif ($choice -eq "F") {
        FullClone -name $NVMName -vm $vm -VMHost $vmhost -data $ds -ReferenceSnapshot $snap
        
    }
    
}
Creation
