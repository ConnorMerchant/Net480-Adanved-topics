# Description : Utilitys for VM managment
#
# Creates a clone based on given inputs and also give the ability to delete VMs 
# Error reporting if something is wrong



# Error Checking


#Get base VM
function VMcloner () {

Get-VM 
$vmi = Read-Host -Prompt "What VM would you like as your base ?"
$vm = Get-VM -Name $vmi
#Get Snapshot target

Get-Snapshot $vmi
$snapshoti= Read-Host -Prompt " Select the snapshot you wish to use."
$snapshot = Get-Snapshot -VM $vmi -Name $snapshoti

#Get vmhost

Get-VMHost
$vmhosti = Read-Host -Prompt "What VMHost would you like to use?"
$vmhost = Get-VMHost -Name $vmhosti

#Get Datastore 

Get-Datastore
$dsi = Read-Host -Prompt "Please enter the datastore you wish to use."
$ds = Get-Datastore -Name $dsi

#Get Linked name
$linkedname = "{0}.linked" -f $vm.name
#Create Linked VM

$linkedvm = New-VM -LinkedClone -Name $linkedname -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds

#Create New VM and asking for its name

$NVMName = Read-Host -Prompt "What would you like to name the New VM?"

$newvm = New-VM -Name $NVMName -VM $linkedvm -VMHost $vmhost -Datastore $ds

$newvm 

#Remover linked VM

$linkedvm| Remove-VM

}

VMcloner