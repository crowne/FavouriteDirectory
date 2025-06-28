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
    Shows the help message for the FavoriteDirectory module.
.DESCRIPTION
    This function displays the usage information for the FavoriteDirectory module.
.OUTPUTS
    None
#>
function Show-FavoriteDirectoryHelp {
    Write-Output "
FavoriteDirectory - A PowerShell module to manage favorite directory aliases.

Usage:
    fd <name>
    fd -a <name> <path>
    fd -l [<name>]
    fd -d <name>
    fd -r
    fd -h | -help

Actions:
    <name>              Go to a favorite directory.
    -a, -add            Add a new favorite directory.
    -l, -list           List all favorite directories or a specific one.
    -d, -delete         Delete a favorite directory.
    -r, -registry       Show the location of the registry.
    -h, -help           Show this help message.
"
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
    param()
    
    $Arguments = $args

    if ($Arguments.Count -eq 0) {
        Show-FavoriteDirectoryHelp
        return
    }

    $Action = $Arguments[0]
    if ($Arguments.Count -gt 1) {
        $Alias = $Arguments[1]
    }
    if ($Arguments.Count -gt 1) {
        $Path = $Arguments[2]
    }
    
    switch ($Action) {
        '-l' {
            if (-not $Alias) {
                Get-FavoriteDirectoryList
            } else {
                Get-FavoriteDirectory -Name $Alias
            }
        }
        '-list' {
            if (-not $Alias) {
                Get-FavoriteDirectoryList
            } else {
                Get-FavoriteDirectory -Name $Alias
            }
        }
        '-a' {
            if (-not $Path) {
                Write-Error "-a or -add requires two arguments: name and path."
                return
            }
            Set-FavoriteDirectory -Name $Alias -Path $Path
        }
        '-add' {
            if (-not $Path) {
                Write-Error "-a or -add requires two arguments: name and path."
                return
            }
            Set-FavoriteDirectory -Name $Alias -Path $Path
        }
        '-d' {
            if (-not $Alias) {
                Write-Error "-d or -delete requires one argument: name."
                return
            }
            Remove-FavoriteDirectory -Name $Alias
        }
        '-delete' {
            if (-not $Alias) {
                Write-Error "-d or -delete requires one argument: name."
                return
            }
            Remove-FavoriteDirectory -Name $Alias
        }
        '-r' {
            Get-FavoriteDirectoryRegistryPath
        }
        '-registry' {
            Get-FavoriteDirectoryRegistryPath
        }
        '-h' {
            Show-FavoriteDirectoryHelp
        }
        '-help' {
            Show-FavoriteDirectoryHelp
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

Export-ModuleMember -Function Get-FavoriteDirectory, Set-FavoriteDirectory, Remove-FavoriteDirectory, Get-FavoriteDirectoryRegistryPath, Get-FavoriteDirectoryList, Invoke-FavoriteDirectory, Show-FavoriteDirectoryHelp -Alias fd