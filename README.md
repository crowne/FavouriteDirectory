# FavouriteDirectory

A PowerShell module to manage favourite directory aliases.
This module was written using Gemini cli, claude-code and co-pilot as a learning kata for me to become familiar with the ai code tools.

## Installation

To install the module, run the following command:

```powershell
Import-Module -Name "C:\github\crowne\FavouriteDirectory\FavouriteDirectory\FavouriteDirectory.psd1"
```

Or add powershell gallery to your
`C:\Users\User.Name\AppData\Roaming\NuGet\nuget.config`

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="Microsoft Visual Studio Offline Packages" value="C:\Program Files (x86)\Microsoft SDKs\NuGetPackages\" />
    <add key="PSGallery" value="https://www.powershellgallery.com/api/v2/" />
  </packageSources>
</configuration>
```

## Usage

### Add a favourite directory

```powershell
fd -a <name> <path>
```

### List favourite directories

```powershell
fd -l
```

### Get a favourite directory

```powershell
fd -l <name>
```

### Remove a favourite directory

```powershell
fd -d <name>
```

### Go to a favourite directory

```powershell
fd <name>
```

## Publishing
Before publishing, run these checks

```powershell
Test-ModuleManifest .\FavouriteDirectory\FavouriteDirectory.psd1
Publish-Module -Path ./FavouriteDirectory -NuGetApiKey ${secret} -WhatIf -Verbose
```


