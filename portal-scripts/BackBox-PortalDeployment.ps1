    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # VHD source URI
        $sourceVHDURI = 'https://stgbbeu.blob.core.windows.net/bbcontainer/BackBoxv6tryFixed.vhd',
        
        # VHD sas token
        $sasToken = 'sp=r&st=2019-03-04T13:55:31Z&se=2025-01-01T21:55:31Z&spr=https&sv=2018-03-28&sig=HbcCGYGdDIhs3Mv9ZmnaKPKhhr6YI4ST8EC8Z254i3U%3D&sr=b'
    )
    
    
    $location= read-host "Please enter location"
    $ErrorActionPreference = 'stop'
    $resourceGroupName = "Backbox-rg"
    $storageaccountname = "backboxstg" + ( -join (1..100 |Get-Random -Count 6))
    $contname = "$storageaccountname-cont"
    $vhd = Split-Path -Leaf $sourceVHDURI 
   
    if (!(Get-AzureRmResourceGroup -name $resourceGroupName -ErrorAction SilentlyContinue )) {
        write-output "Creating New Resource group: $resourceGroupName"
        $RG = New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
    } else {$RG = Get-AzureRmResourceGroup -name $resourceGroupName}
    
    write-output "Creating New Storageaccount: $storageaccountname"
    $stg = New-AzureRmStorageAccount -ResourceGroupName $rg.ResourceGroupName -Name $storageaccountname -SkuName Standard_LRS -Location $location -Kind StorageV2 -AccessTier Cool
    write-output "Creating New Container: $contname"
    $cont = New-AzureRmStorageContainer -StorageAccountName $storageaccountname -ResourceGroupName $rg.ResourceGroupName -Name $contname

    Write-Output "Start Time: $(get-date)"
    Write-Output "Start copy backbox VHD"

    $blob = Start-AzureStorageBlobCopy -AbsoluteUri ($sourceVHDURI + "?" + $sasToken) -DestContainer $cont.Name -DestBlob $vhd -DestContext $stg.Context
    $blob| Get-AzureStorageBlobCopyState

    Do {Write-Output "copy status is: $(($blob| Get-AzureStorageBlobCopyState).Status)"; sleep -Seconds 10} Until (($blob| Get-AzureStorageBlobCopyState).Status -ne "Pending")
    Write-Output "End Time: $(get-date)"

    $newUri = "$($blob.context.BlobEndPoint)" + "$($cont.name)/" + "$vhd" #+ $sas
    Write-Output "New URI: $newUri"  
