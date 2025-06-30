function makeDir([string]$dir_name) {
    if ( !( Test-Path $dir_name -PathType Container ) ) {
        Write-Host "Creating $dir_name"
        mkdir $dir_name
    }
}

$profile_dir = Split-Path -Path $Profile -Parent
makeDir($profile_dir)
$modules_home = Join-Path -Path $profile_dir -ChildPath "modules"
Remove-Item -Path $modules_home/FavouriteDirectory -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -Recurse ./FavouriteDirectory $modules_home
