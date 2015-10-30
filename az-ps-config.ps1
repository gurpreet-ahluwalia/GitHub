Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1'
$ErrorActionPreference="Stop"

$subscriptionName = ""
$subscriptionID = ""
$location = ""
$storageAccount = ""

Write-Output "Retrieving Credentials" 
Add-AzureAccount 
    
$subscriptions = Get-AzureSubscription 

# No Subscription
if($subscriptions.Count -eq 0)
{
    Write-Output "No subscriptions found. Login with an organization account that has access to a Microsoft Azure Subscription"
    return
}

# Multiple subscriptions 
if($subscriptions.Count -gt 1)
{
    while($true)
    {
        for($i=1;$i -lt ($subscriptions.Count + 1); $i++)
        {
            Write-Host "[$i] - " $subscriptions[$i-1].SubscriptionName "- ID: " $subscriptions[$i-1].SubscriptionId
        }

        Write-Host 
        $selectedSubscription = Read-Host -Prompt "Select a Subscription to Use" 
        Write-Host 

        # validate they selected a number
        [int] $selectedNumber = $null
        if([int32]::TryParse($selectedSubscription, [ref]$selectedNumber) -eq $true)
        {
            # Validate it is within the range of subscriptions 
            if($selectedNumber -ge 1 -and $selectedNumber  -lt ($subscriptions.Count + 1))
            {
                Write-Host "Using subscription: " $subscriptions[$selectedNumber - 1].SubscriptionName " ID: " $subscriptions[$selectedNumber - 1].SubscriptionId
                $subscriptionName = $subscriptions[$selectedNumber - 1].SubscriptionName
                $subscriptionID = $subscriptions[$selectedNumber - 1].SubscriptionId
                Select-AzureSubscription -SubscriptionId $subscriptionID 
                break               
            }
        }
    }
}
# only 1 subscription
else 
{
    Write-Host "Using subscription: " $subscriptions[0].SubscriptionName " ID: " $subscriptions[0].SubscriptionId
    $subscriptionName = $subscriptions[0].SubscriptionName
    $subscriptionID = $subscriptions[$selectedNumber - 1].SubscriptionId
    Select-AzureSubscription -SubscriptionId $subscriptionID 
}


# select the location to use 
$locations = Get-AzureLocation | where { $_.AvailableServices.Contains("PersistentVMRole") } | select name

while($true)
{
    for($i=1;$i -lt ($locations.Count + 1); $i++)
    {
        Write-Host "[$i] - " $locations[$i-1].Name
    }

    Write-Host 
    $selectedLocation = Read-Host -Prompt "Select a Location to Use " 
    Write-Host 

    # validate they selected a number
    [int] $selectedNumber = $null
    if([int32]::TryParse($selectedLocation, [ref]$selectedNumber) -eq $true)
    {
        # Validate it is within the range of locations 
        if($selectedNumber -ge 1 -and $selectedNumber  -lt ($locations.Count + 1))
        {
            $location = $locations[$selectedNumber - 1].Name
            break               
        }
    }
}



function CreateStorageAccount()
{
    while($true)
    {
        $newStorageAccountName = Read-Host -Prompt "Enter a Name for your Storage Account" 

        $testResult = Test-AzureName -Storage -Name $newStorageAccountName -ErrorAction SilentlyContinue
        if($testResult -eq $true -or $testResult -eq $null)
        {
            Write-Host "Storage account name is either in use or is not a valid name." -ForegroundColor Red
        }
        else
        {
            Write-Host "Creating Storage Account... " -ForegroundColor Green
            New-AzureStorageAccount -StorageAccountName $newStorageAccountName -Location $location
            Set-AzureSubscription -SubscriptionName $subscriptionName -CurrentStorageAccountName $newStorageAccountName
            break
        }
    }
}

# select the storage account to use 
$usableStorageAccounts = Get-AzureStorageAccount | Where { $_.Location -eq $location } | select StorageAccountName

# Need to create a storage account 
if($usableStorageAccounts -eq $null)
{
    CreateStorageAccount
}

# Need to select an existing storage account
if($usableStorageAccounts -ne $null)
{
    while($true)
    {
        # if only one the return value is not an array
        if($usableStorageAccounts.Count -eq $null) 
        {
           Write-Host "[1] - " $usableStorageAccounts.StorageAccountName
        }
        else
        {
            for($i=1;$i -lt ($usableStorageAccounts.Count + 1); $i++)
            {
                Write-Host "[$i] - "$usableStorageAccounts[$i-1].StorageAccountName
            }
        }
        $i++
        Write-Host "[N] - Create New Storage Account" 
        Write-Host 
        $selectedStorageAccount = Read-Host -Prompt "Select an Existing Storage Account or Create a New One" 
        Write-Host

        if($selectedStorageAccount -eq "n" -or $selectedStorageAccount -eq "N")
        {
            CreateStorageAccount
            break
        }
        else
        {
            # validate they selected a number
            [int] $selectedNumber = $null
            if([int32]::TryParse($selectedStorageAccount, [ref]$selectedNumber) -eq $true)
            {
                # Validate it is within the range of storage accounts 
                # first condition = only one storage account 
                # second is if there are multiple
                if($selectedNumber -eq 1 -and $usableStorageAccounts.Count -eq $null -or ($selectedNumber -ge 1 -and $selectedNumber  -lt ($usableStorageAccounts.Count + 1)))
                {
                    $storageAccount = $usableStorageAccounts[$selectedNumber - 1].StorageAccountName
                    Set-AzureSubscription -SubscriptionId $subscriptionID -CurrentStorageAccountName $storageAccount
                    break               
                }
            }
        }
    }
}


Write-Host "Microsoft Azure PowerShell is now Configured" -ForegroundColor Green

