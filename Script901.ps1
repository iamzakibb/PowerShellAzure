$AppID = ""
$Secret = ""
$TenantID = ""

$secureClientSecret = ConvertTo-SecureString $Secret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($AppID, $secureClientSecret)
Connect-AzAccount -ServicePrincipal -Tenant $tenantId -Credential $credential

# arrays 
$ManagementGroups = New-Object System.Collections.Generic.List[object]
$CustomSubscriptions = New-Object System.Collections.Generic.List[object]
$Resources = New-Object System.Collections.Generic.List[object]
$Permissions = New-Object System.Collections.Generic.List[object]

# Step 1: Collect Management Groups
Write-Host "Collecting Management Groups..."
$mgmtGroups = Get-AzManagementGroup
if ($mgmtGroups) {
    $mgmtGroups | ForEach-Object {
        $mgObj = [pscustomobject][ordered]@{
            id           = [string]$_.Id
            name         = [string]$_.Name
            displayName  = [string]$_.DisplayName
            tenantId     = [string]$TenantID
        }
        [void]($ManagementGroups.Add($mgObj))
    }
    Write-Host "Collected $($ManagementGroups.Count) Management Groups"
} else {
    Write-Host "No Management Groups found."
}

# Step 2: Collect Subscriptions
Write-Host "Collecting Subscriptions..."
$subscriptions = Get-AzSubscription
if ($subscriptions) {
    $subscriptions | ForEach-Object {
        $subObj = [pscustomobject][ordered]@{
            id                 = [string]$_.Id
            name               = [string]$_.Name
            state              = [string]$_.State
            tenantId           = [string]$TenantID
            managementGroupId  = [string]($ManagementGroups | Where-Object { $_.tenantId -eq $TenantID }).id
        }
        [void]($CustomSubscriptions.Add($subObj))
    }
    Write-Host "Collected $($CustomSubscriptions.Count) Subscriptions"
} else {
    Write-Host "No Subscriptions found."
}

# Step 3: Collect Resources
Write-Host "Collecting Resources..."
$resources = Get-AzResource
if ($resources) {
    $resources | ForEach-Object {
        $resObj = [pscustomobject][ordered]@{
            id              = [string]$_.ResourceId
            name            = [string]$_.Name
            type            = [string]$_.ResourceType
            location        = [string]$_.Location
            subscriptionId  = [string]$_.SubscriptionId
            tenantId        = [string]$TenantID
        }
        [void]($Resources.Add($resObj))
    }
    Write-Host "Collected $($Resources.Count) Resources"
} else {
    Write-Host "No Resources found."
}

# Step 4: Collect Permissions
Write-Host "Collecting Permissions..."
if ($subscriptions) {
    $subscriptions | ForEach-Object {
        $roleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$($_.Id)"
        if ($roleAssignments) {
            $roleAssignments | ForEach-Object {
                $permObj = [pscustomobject][ordered]@{
                    principalName  = [string]$_.PrincipalName
                    roleName       = [string]$_.RoleDefinitionName
                    principalType  = [string]$_.PrincipalType
                    scope          = [string]$_.Scope
                    subscriptionId = [string]$_.Id
                    tenantId       = [string]$TenantID
                }
                [void]($Permissions.Add($permObj))
            }
        }
    }
    Write-Host "Collected $($Permissions.Count) Permissions"
} else {
    Write-Host "No Permissions found."
}

# Step 5: Print the output
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
