function Get-FavoriteDirectoryRegistryPath {
    $appDataPath = [System.Environment]::GetFolderPath('ApplicationData')
    $registryDir = Join-Path -Path $appDataPath -ChildPath 'FavoriteDirectory'
    if (-not (Test-Path -Path $registryDir)) {
        New-Item -Path $registryDir -ItemType Directory -Force | Out-Null
    }
    Join-Path -Path $registryDir -ChildPath 'FavoriteDirectoryRegistry.json'
}

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
            $registry = $content | ConvertFrom-Json
            if ($registry.PSObject.Properties.Name -contains $Name) {
                return $registry.$Name
            }
        }
    }
    Write-Error "Favorite directory '$Name' not found."
}

function Set-FavoriteDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Path
    )

    $registryPath = Get-FavoriteDirectoryRegistryPath
    $registry = @{}
    if (Test-Path -Path $registryPath) {
        $content = Get-Content -Path $registryPath -Raw
        if (-not [string]::IsNullOrWhiteSpace($content)) {
            $registry = $content | ConvertFrom-Json
        }
    }

    if ($registry.PSObject.Properties.Name -contains $Name) {
        $registry.$Name = $Path
    } else {
        $registry | Add-Member -MemberType NoteProperty -Name $Name -Value $Path
    }

    $registry | ConvertTo-Json | Set-Content -Path $registryPath
}

function Remove-FavoriteDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    $registryPath = Get-FavoriteDirectoryRegistryPath
    if (-not (Test-Path -Path $registryPath)) {
        Write-Error "Favorite directory registry not found."
        return
    }
    
    $content = Get-Content -Path $registryPath -Raw
    if ([string]::IsNullOrWhiteSpace($content)) {
        Write-Error "Favorite directory '$Name' not found."
        return
    }

    $registry = $content | ConvertFrom-Json
    if ($registry.PSObject.Properties.Name -contains $Name) {
        $registry.PSObject.Properties.Remove($Name)
        $registry | ConvertTo-Json | Set-Content -Path $registryPath
    } else {
        Write-Error "Favorite directory '$Name' not found."
    }
}

Export-ModuleMember -Function Get-FavoriteDirectory, Set-FavoriteDirectory, Remove-FavoriteDirectory