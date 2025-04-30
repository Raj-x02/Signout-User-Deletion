Set-ExecutionPolicy Unrestricted -Force
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force

# Get all logged-in users and their session IDs
$users = query session | ForEach-Object {
    $parts = ($_ -replace '\s{2,}', ',').Split(',')
    if ($parts.Count -ge 3) {
        [PSCustomObject]@{
            Username = $parts[1].Trim()
            SessionID = $parts[2].Trim()
        }
    }
}

# Log out all users except "sysadmin"
foreach ($user in $users) {
    if ($user.Username -ne "sysadmin") {
        Write-Host "Logging out user: $($user.Username)"
        logoff $user.SessionID
    }
}

# Define the list of users to exclude
$excludedUsers = @("administrator", "sysadmin", "admin", "user", "ARM1593")

# Get all local user profiles
$users = Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.Special -eq $false }

foreach ($user in $users) {
    $username = $user.LocalPath.Split('\')[-1]
    
    # Skip the users listed in the exclusion array
    if ($excludedUsers -contains $username) {
        Write-Host "Skipping profile for user: $username"
        continue
    }

    try {
        # Delete user profile properly using Win32_UserProfile
        Write-Host "Deleting profile for user: $username"
        $user.Delete()
    } catch {
        Write-Host "Failed to delete profile for user: $username. Error: $($_.Exception.Message)"
    }
}

Write-Host "Profile deletion script completed."
