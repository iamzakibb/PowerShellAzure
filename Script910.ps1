# Variables for the Service Principal
$tenantId = "your-tenant-id"
$clientId = "your-client-id"
$clientSecret = "your-client-secret"

# Connect to Azure using the Service Principal
$secureClientSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($clientId, $secureClientSecret)

Connect-AzAccount -ServicePrincipal -Tenant $tenantId -Credential $credential

# Initialize arrays to store data
$managementGroupsData = @()
$subscriptionsData = @()
$resourcesData = @()
$permissionsData = @()

# Collect Management Groups
$managementGroups = Get-AzManagementGroup

foreach ($mg in $managementGroups) {
    $mgObject = [pscustomobject][ordered]@{
        id                  = $mg.Id                        # string
        managementGroupId   = $mg.Id                        # string
        managementGroupName = $mg.DisplayName               # string
    }
    $managementGroupsData += $mgObject

    # Collect role assignments (permissions) for the management group
    $mgRoleAssignments = Get-AzRoleAssignment -Scope "/providers/Microsoft.Management/managementGroups/$($mg.Name)"
    foreach ($roleAssignment in $mgRoleAssignments) {
        $permissionsObject = [pscustomobject][ordered]@{
            scope           = "Management Group"            # string
            id              = $mg.Id                        # string
            principalId     = $roleAssignment.PrincipalId   # string
            roleName        = $roleAssignment.RoleDefinitionName # string
        }
        $permissionsData += $permissionsObject
    }
}

# Collect Subscriptions
$subscriptions = Get-AzSubscription

foreach ($subscription in $subscriptions) {
    $subscriptionObject = [pscustomobject][ordered]@{
        id                = $subscription.Id                 # string
        subscriptionId    = $subscription.Id                 # string
        subscriptionName  = $subscription.Name               # string
        managementGroupId = $managementGroups.Where({$_.Id -match $subscription.ManagementGroupId}).Id  # string
    }
    $subscriptionsData += $subscriptionObject

    # Collect role assignments (permissions) for the subscription
    $subRoleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$($subscription.Id)"
    foreach ($roleAssignment in $subRoleAssignments) {
        $permissionsObject = [pscustomobject][ordered]@{
            scope           = "Subscription"                 # string
            id              = $subscription.Id               # string
            principalId     = $roleAssignment.PrincipalId    # string
            roleName        = $roleAssignment.RoleDefinitionName # string
        }
        $permissionsData += $permissionsObject
    }
}

# Collect Resources within each Subscription
foreach ($subscription in $subscriptions) {
    # Set the context to the current subscription
    Set-AzContext -SubscriptionId $subscription.Id

    # Collect resources in the subscription
    $resources = Get-AzResource

    foreach ($resource in $resources) {
        $resourceObject = [pscustomobject][ordered]@{
            id              = $resource.ResourceId             # string
            resourceId      = $resource.ResourceId             # string
            resourceName    = $resource.Name                   # string
            resourceType    = $resource.ResourceType           # string
            resourceGroup   = $resource.ResourceGroupName      # string
            subscriptionId  = $subscription.Id                 # string
        }
        $resourcesData += $resourceObject

        # Collect role assignments (permissions) for the resource
        $resourceRoleAssignments = Get-AzRoleAssignment -Scope $resource.ResourceId
        foreach ($roleAssignment in $resourceRoleAssignments) {
            $permissionsObject = [pscustomobject][ordered]@{
                scope           = "Resource"                    # string
                id              = $resource.ResourceId          # string
                principalId     = $roleAssignment.PrincipalId   # string
                roleName        = $roleAssignment.RoleDefinitionName # string
            }
            $permissionsData += $permissionsObject
        }
    }
}

# Print the structured output to the console with data types
Write-Host "Management Groups:"
$managementGroupsData | ForEach-Object {
    Write-Host "id (string): $($_.id)"
    Write-Host "managementGroupId (string): $($_.managementGroupId)"
    Write-Host "managementGroupName (string): $($_.managementGroupName)"
    Write-Host "`n"
}

Write-Host "`nSubscriptions:"
$subscriptionsData | ForEach-Object {
    Write-Host "id (string): $($_.id)"
    Write-Host "subscriptionId (string): $($_.subscriptionId)"
    Write-Host "subscriptionName (string): $($_.subscriptionName)"
    Write-Host "managementGroupId (string): $($_.managementGroupId)"
    Write-Host "`n"
}

Write-Host "`nResources:"
$resourcesData | ForEach-Object {
    Write-Host "id (string): $($_.id)"
    Write-Host "resourceId (string): $($_.resourceId)"
    Write-Host "resourceName (string): $($_.resourceName)"
    Write-Host "resourceType (string): $($_.resourceType)"
    Write-Host "resourceGroup (string): $($_.resourceGroup)"
    Write-Host "subscriptionId (string): $($_.subscriptionId)"
    Write-Host "`n"
}

Write-Host "`nPermissions:"
$permissionsData | ForEach-Object {
    Write-Host "scope (string): $($_.scope)"
    Write-Host "id (string): $($_.id)"
    Write-Host "principalId (string): $($_.principalId)"
    Write-Host "roleName (string): $($_.roleName)"
    Write-Host "`n"
}

Write-Host "`nData collection complete."
