<#
.SYNOPSIS
    Gets the path to the favorite directory registry file.
.DESCRIPTION
    This function returns the path to the favorite directory registry file. It creates the directory if it does not exist.
.OUTPUTS
    System.String
#>
function Get-FavoriteDirectoryRegistryPath {
    $appDataPath = [System.Environment]::GetFolderPath('ApplicationData')
    $registryDir = Join-Path -Path $appDataPath -ChildPath 'FavoriteDirectory'
    if (-not (Test-Path -Path $registryDir)) {
        New-Item -Path $registryDir -ItemType Directory -Force | Out-Null
    }
    Join-Path -Path $registryDir -ChildPath 'FavoriteDirectoryRegistry.json'
}

<#
.SYNOPSIS
    Gets a favorite directory by name.
.DESCRIPTION
    This function retrieves a favorite directory by its name from the registry.
.PARAMETER Name
    The name of the favorite directory to retrieve.
.INPUTS
    System.String
.OUTPUTS
    System.String
#>
function Get-FavoriteDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Name
    )

    $registryPath = Get-FavoriteDirectoryRegistryPath
    if (Test-Path -Path $registryPath) {
        $content = Get-Content -Path $registryPath -Raw
        if (-not [string]::IsNullOrWhiteSpace($content)) {
            $registry = $content | ConvertFrom-Json -AsHashtable
            if ($registry.ContainsKey($Name)) {
                return $registry.$Name
            }
        }
    }
    Write-Warning "Favorite directory '$Name' not found."
    return $null
}

<#
.SYNOPSIS
    Sets a favorite directory.
.DESCRIPTION
    This function sets a favorite directory by name and path.
.PARAMETER Name
    The name of the favorite directory to set.
.PARAMETER Path
    The path of the favorite directory to set.
.INPUTS
    System.String
.OUTPUTS
    None
#>
function Set-FavoriteDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Path
    )

    if ($Name.StartsWith('-')) {
        throw "Favorite directory name cannot start with a hyphen."
    }

    $registryPath = Get-FavoriteDirectoryRegistryPath
    $registry = @{}
    if (Test-Path -Path $registryPath) {
        $content = Get-Content -Path $registryPath -Raw
        if (-not [string]::IsNullOrWhiteSpace($content)) {
            $registry = $content | ConvertFrom-Json -AsHashtable
        }
    }

    $registry[$Name] = $Path

    $registry | ConvertTo-Json | Set-Content -Path $registryPath
}

<#
.SYNOPSIS
    Removes a favorite directory.
.DESCRIPTION
    This function removes a favorite directory by name.
.PARAMETER Name
    The name of the favorite directory to remove.
.INPUTS
    System.String
.OUTPUTS
    None
#>
function Remove-FavoriteDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    $registryPath = Get-FavoriteDirectoryRegistryPath
    if (-not (Test-Path -Path $registryPath)) {
        Write-Error "Favorite directory registry not found." -ErrorAction Stop
        return
    }
    
    $content = Get-Content -Path $registryPath -Raw
    if ([string]::IsNullOrWhiteSpace($content)) {
        Write-Error "Favorite directory '$Name' not found."
        return
    }

    $registry = $content | ConvertFrom-Json -AsHashtable
    if ($registry.ContainsKey($Name)) {
        $registry.Remove($Name)
        $registry | ConvertTo-Json | Set-Content -Path $registryPath
    } else {
        Write-Warning "Favorite directory '$Name' not found."
    }
}

<#
.SYNOPSIS
    Gets the list of favorite directories.
.DESCRIPTION
    This function retrieves the list of favorite directories from the registry.
.OUTPUTS
    System.Collections.Hashtable
#>
function Get-FavoriteDirectoryList {
    [CmdletBinding()]
    param ()

    $registryPath = Get-FavoriteDirectoryRegistryPath
    if (-not (Test-Path -Path $registryPath)) {
        return @{}
    }
    
    $content = Get-Content -Path $registryPath -Raw
    if ([string]::IsNullOrWhiteSpace($content)) {
        return @{}
    }

    return $content | ConvertFrom-Json -AsHashtable
}

<#
.SYNOPSIS
    Invokes a favorite directory action.
.DESCRIPTION
    This function invokes a favorite directory action based on the provided parameters.
.PARAMETER Action
    The action to perform.
.PARAMETER Arguments
    The arguments for the action.
.INPUTS
    System.String
.OUTPUTS
    None
#>
function Invoke-FavoriteDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Action,

        [string[]]$Arguments
    )

    switch ($Action) {
        '-l' {
            if ($Arguments.Length -eq 0) {
                Get-FavoriteDirectoryList
            } else {
                Get-FavoriteDirectory -Name $Arguments[0]
            }
        }
        '-list' {
            if ($Arguments.Length -eq 0) {
                Get-FavoriteDirectoryList
            } else {
                Get-FavoriteDirectory -Name $Arguments[0]
            }
        }
        '-a' {
            if ($Arguments.Length -ne 2) {
                Write-Error "-a or -add requires two arguments: name and path."
                return
            }
            Set-FavoriteDirectory -Name $Arguments[0] -Path $Arguments[1]
        }
        '-add' {
            if ($Arguments.Length -ne 2) {
                Write-Error "-a or -add requires two arguments: name and path."
                return
            }
            Set-FavoriteDirectory -Name $Arguments[0] -Path $Arguments[1]
        }
        '-d' {
            if ($Arguments.Length -ne 1) {
                Write-Error "-d or -delete requires one argument: name."
                return
            }
            Remove-FavoriteDirectory -Name $Arguments[0]
        }
        '-delete' {
            if ($Arguments.Length -ne 1) {
                Write-Error "-d or -delete requires one argument: name."
                return
            }
            Remove-FavoriteDirectory -Name $Arguments[0]
        }
        default {
            $path = Get-FavoriteDirectory -Name $Action
            if ($path) {
                Set-Location -Path $path
            }
        }
    }
}

New-Alias -Name fd -Value Invoke-FavoriteDirectory

Export-ModuleMember -Function Get-FavoriteDirectory, Set-FavoriteDirectory, Remove-FavoriteDirectory, Get-FavoriteDirectoryRegistryPath, Get-FavoriteDirectoryList, Invoke-FavoriteDirectory -Alias fd