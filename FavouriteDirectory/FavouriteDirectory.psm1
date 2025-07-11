<#
.SYNOPSIS
    Gets the path to the favourite directory registry file.
.DESCRIPTION
    This function returns the path to the favourite directory registry file. It creates the directory if it does not exist.
.OUTPUTS
    System.String
#>
function Get-FavouriteDirectoryRegistryPath {
    $appDataPath = [System.Environment]::GetFolderPath('ApplicationData')
    $registryDir = Join-Path -Path $appDataPath -ChildPath 'FavouriteDirectory'
    if (-not (Test-Path -Path $registryDir)) {
        New-Item -Path $registryDir -ItemType Directory -Force | Out-Null
    }
    Join-Path -Path $registryDir -ChildPath 'FavouriteDirectoryRegistry.json'
}

<#
.SYNOPSIS
    Gets a favourite directory by name.
.DESCRIPTION
    This function retrieves a favourite directory by its name from the registry.
.PARAMETER Name
    The name of the favourite directory to retrieve.
.INPUTS
    System.String
.OUTPUTS
    System.String
#>
function Get-FavouriteDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Name
    )

    $registryPath = Get-FavouriteDirectoryRegistryPath
    if (Test-Path -Path $registryPath) {
        $content = Get-Content -Path $registryPath -Raw
        if (-not [string]::IsNullOrWhiteSpace($content)) {
            $registry = $content | ConvertFrom-Json -AsHashtable
            if ($registry.ContainsKey($Name)) {
                return $registry.$Name
            }
        }
    }
    Write-Warning "Favourite directory '$Name' not found."
    return $null
}

<#
.SYNOPSIS
    Sets a favourite directory.
.DESCRIPTION
    This function sets a favourite directory by name and path.
.PARAMETER Name
    The name of the favourite directory to set.
.PARAMETER Path
    The path of the favourite directory to set.
.INPUTS
    System.String
.OUTPUTS
    None
#>
<#
.SYNOPSIS
    Saves the favourite directory registry.
.DESCRIPTION
    This function saves the favourite directory registry to a file, ensuring the entries are sorted by name.
.PARAMETER Registry
    The hashtable representing the registry.
.PARAMETER Path
    The path to the registry file.
.INPUTS
    System.Collections.Hashtable
    System.String
.OUTPUTS
    None
#>
function Save-FavouriteDirectoryRegistry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]$Registry,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $sortedRegistry = [System.Collections.Specialized.OrderedDictionary]@{}
    $Registry.GetEnumerator() | Sort-Object Name | ForEach-Object {
        $sortedRegistry[$_.Name] = $_.Value
    }

    $sortedRegistry | ConvertTo-Json | Set-Content -Path $Path
}

<#
.SYNOPSIS
    Sets a favourite directory.
.DESCRIPTION
    This function sets a favourite directory by name and path.
.PARAMETER Name
    The name of the favourite directory to set.
.PARAMETER Path
    The path of the favourite directory to set.
.INPUTS
    System.String
.OUTPUTS
    None
#>
function Set-FavouriteDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Path
    )

    if ($Name.StartsWith('-')) {
        throw "Favourite directory name cannot start with a hyphen."
    }

    $registryPath = Get-FavouriteDirectoryRegistryPath
    $registry = @{}
    if (Test-Path -Path $registryPath) {
        $content = Get-Content -Path $registryPath -Raw
        if (-not [string]::IsNullOrWhiteSpace($content)) {
            $registry = $content | ConvertFrom-Json -AsHashtable
        }
    }

    $registry[$Name] = $Path

    Save-FavouriteDirectoryRegistry -Registry $registry -Path $registryPath
}

<#
.SYNOPSIS
    Removes a favourite directory.
.DESCRIPTION
    This function removes a favourite directory by name.
.PARAMETER Name
    The name of the favourite directory to remove.
.INPUTS
    System.String
.OUTPUTS
    None
#>
function Remove-FavouriteDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    $registryPath = Get-FavouriteDirectoryRegistryPath
    if (-not (Test-Path -Path $registryPath)) {
        Write-Error "Favourite directory registry not found." -ErrorAction Stop
        return
    }
    
    $content = Get-Content -Path $registryPath -Raw
    if ([string]::IsNullOrWhiteSpace($content)) {
        Write-Error "Favourite directory '$Name' not found."
        return
    }

    $registry = $content | ConvertFrom-Json -AsHashtable
    if ($registry.ContainsKey($Name)) {
        $registry.Remove($Name)
        Save-FavouriteDirectoryRegistry -Registry $registry -Path $registryPath
    } else {
        Write-Warning "Favourite directory '$Name' not found."
    }
}

<#
.SYNOPSIS
    Gets the list of favourite directories.
.DESCRIPTION
    This function retrieves the list of favourite directories from the registry.
.OUTPUTS
    System.Collections.Hashtable
#>
function Get-FavouriteDirectoryList {
    [CmdletBinding()]
    param ()

    $registryPath = Get-FavouriteDirectoryRegistryPath
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
    Gets the version of favourite directory module.
.DESCRIPTION
    This function returns the version of favourite directory module.
.OUTPUTS
    System.String
#>
function Get-FavouriteDirectoryVersion {
        # Get the path to the manifest file
        $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath 'FavouriteDirectory.psd1'
        # Import the manifest as a hashtable
        $manifest = Import-PowerShellDataFile -Path $manifestPath
        return $manifest.ModuleVersion
}

<#
.SYNOPSIS
    Shows the help message for the FavouriteDirectory module.
.DESCRIPTION
    This function displays the usage information for the FavouriteDirectory module.
.OUTPUTS
    None
#>
function Show-FavouriteDirectoryHelp {
    Write-Output "
FavouriteDirectory - A PowerShell module to manage favourite directory aliases.

Usage:
    fd
    fd <name>
    fd -a <name> <path>
    fd -l [<name>]
    fd -d <name>
    fd -r
    fd -v
    fd -h | -help

Actions:
    <no arguments>      Show a list of all favourite directories.
    <name>              Go to a favourite directory.
    -a, -add            Add a new favourite directory.
    -l, -list           List all favourite directories or a specific one.
    -d, -delete         Delete a favourite directory.
    -r, -registry       Show the location of the registry.
    -v, -version        Show the module version number.
    -h, -help           Show this help message.
"
}

<#
.SYNOPSIS
    Invokes a favourite directory action.
.DESCRIPTION
    This function invokes a favourite directory action based on the provided parameters.
.PARAMETER Action
    The action to perform.
.PARAMETER Arguments
    The arguments for the action.
.INPUTS
    System.String
.OUTPUTS
    None
#>
function Invoke-FavouriteDirectory {
    param()
    
    $Arguments = $args

    if ($Arguments.Count -eq 0) {
        Write-Output "For help options try fd -h"
        Get-FavouriteDirectoryList
        return
    }

    $Action = $Arguments[0]
    if ($Arguments.Count -gt 1) {
        $Alias = $Arguments[1]
    }
    if ($Arguments.Count -gt 2) {
        $Path = $Arguments[2]
    }
    
    switch ($Action) {
        '-l' {
            if (-not $Alias) {
                Get-FavouriteDirectoryList
            } else {
                Get-FavouriteDirectory -Name $Alias
            }
        }
        '-list' {
            if (-not $Alias) {
                Get-FavouriteDirectoryList
            } else {
                Get-FavouriteDirectory -Name $Alias
            }
        }
        '-a' {
            if (-not $Path) {
                Write-Error "-a or -add requires two arguments: name and path."
                return
            }
            Set-FavouriteDirectory -Name $Alias -Path $Path
        }
        '-add' {
            if (-not $Path) {
                Write-Error "-a or -add requires two arguments: name and path."
                return
            }
            Set-FavouriteDirectory -Name $Alias -Path $Path
        }
        '-d' {
            if (-not $Alias) {
                Write-Error "-d or -delete requires one argument: name."
                return
            }
            Remove-FavouriteDirectory -Name $Alias
        }
        '-delete' {
            if (-not $Alias) {
                Write-Error "-d or -delete requires one argument: name."
                return
            }
            Remove-FavouriteDirectory -Name $Alias
        }
        '-r' {
            Get-FavouriteDirectoryRegistryPath
        }
        '-registry' {
            Get-FavouriteDirectoryRegistryPath
        }
        '-v' {
            Write-Output "FavouriteDirectory-$(Get-FavouriteDirectoryVersion)"
        }
        '-version' {
            Write-Output "FavouriteDirectory-$(Get-FavouriteDirectoryVersion)"
        }
        '-h' {
            Show-FavouriteDirectoryHelp
        }
        '-help' {
            Show-FavouriteDirectoryHelp
        }
        default {
            $path = Get-FavouriteDirectory -Name $Action
            if ($path) {
                Set-Location -Path $path
            }
        }
    }
}

New-Alias -Name fd -Value Invoke-FavouriteDirectory

Export-ModuleMember -Function Get-FavouriteDirectory, Set-FavouriteDirectory, Remove-FavouriteDirectory, Get-FavouriteDirectoryRegistryPath, Get-FavouriteDirectoryList, Get-FavouriteDirectoryVersion, Invoke-FavouriteDirectory, Show-FavouriteDirectoryHelp, Save-FavouriteDirectoryRegistry -Alias fd