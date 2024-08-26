
$AppID = ""
$Secret = ""
$TenantID = ""

$secureClientSecret = ConvertTo-SecureString $Secret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($AppID, $secureClientSecret)
Connect-AzAccount -ServicePrincipal -Tenant $tenantId -Credential $credential


# Array objects to hold data
$ManagementGroups = @()
$CustomSubscriptions = @()
$Resources = @()
$Permissions = @()

# Step 1: Collect Management Groups
$mgmtGroups = Get-AzManagementGroup
foreach ($mg in $mgmtGroups) {
    $mgObj = [pscustomobject][ordered]@{
        id               = [string]$mg.Id
        name             = [string]$mg.Name
        displayName      = [string]$mg.DisplayName
        tenantId         = [string]$TenantID
    }
    $ManagementGroups += $mgObj
}

# Step 2: Collect Subscriptions
$subscriptions = Get-AzSubscription
foreach ($sub in $subscriptions) {
    $subObj = [pscustomobject][ordered]@{
        id               = [string]$sub.Id
        name             = [string]$sub.Name
        state            = [string]$sub.State
        tenantId         = [string]$TenantID
        managementGroupId = [string]($ManagementGroups | Where-Object { $_.tenantId -eq $TenantID }).id
    }
    $CustomSubscriptions += $subObj
}

# Step 3: Collect Resources
$resources = Get-AzResource
foreach ($res in $resources) {
    $resObj = [pscustomobject][ordered]@{
        id                = [string]$res.ResourceId
        name              = [string]$res.Name
        type              = [string]$res.ResourceType
        location          = [string]$res.Location
        subscriptionId    = [string]$res.SubscriptionId
        tenantId          = [string]$TenantID
    }
    $Resources += $resObj
}

# Step 4: Collect Permissions
foreach ($sub in $subscriptions) {
    $roleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$($sub.Id)"
    foreach ($roleAssignment in $roleAssignments) {
        $permObj = [pscustomobject][ordered]@{
            principalName    = [string]$roleAssignment.PrincipalName
            roleName         = [string]$roleAssignment.RoleDefinitionName
            principalType    = [string]$roleAssignment.PrincipalType
            scope            = [string]$roleAssignment.Scope
            subscriptionId   = [string]$sub.Id
            tenantId         = [string]$TenantID
        }
        $Permissions += $permObj
    }
}

# Step 5: Print the structured output
Write-Host "Management Groups:`n"
$ManagementGroups | ForEach-Object {
    Write-Host "id (string): $($_.id)"
    Write-Host "name (string): $($_.name)"
    Write-Host "displayName (string): $($_.displayName)"
    Write-Host "tenantId (string): $($_.tenantId)"
    Write-Host "`n"
}

Write-Host "Subscriptions:`n"
$CustomSubscriptions | ForEach-Object {
    Write-Host "id (string): $($_.id)"
    Write-Host "name (string): $($_.name)"
    Write-Host "state (string): $($_.state)"
    Write-Host "tenantId (string): $($_.tenantId)"
    Write-Host "managementGroupId (string): $($_.managementGroupId)"
    Write-Host "`n"
}

Write-Host "Resources:`n"
$Resources | ForEach-Object {
    Write-Host "id (string): $($_.id)"
    Write-Host "name (string): $($_.name)"
    Write-Host "type (string): $($_.type)"
    Write-Host "location (string): $($_.location)"
    Write-Host "subscriptionId (string): $($_.subscriptionId)"
    Write-Host "tenantId (string): $($_.tenantId)"
    Write-Host "`n"
}

Write-Host "Permissions:`n"
$Permissions | ForEach-Object {
    Write-Host "principalName (string): $($_.principalName)"
    Write-Host "roleName (string): $($_.roleName)"
    Write-Host "principalType (string): $($_.principalType)"
    Write-Host "scope (string): $($_.scope)"
    Write-Host "subscriptionId (string): $($_.subscriptionId)"
    Write-Host "tenantId (string): $($_.tenantId)"
    Write-Host "`n"
}
