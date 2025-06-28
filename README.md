# FavouriteDirectory

A PowerShell module to manage favourite directory aliases.
This module was written using Gemini cli, claude-code and co-pilot as a learning kata for me to become familiar with the ai code tools.

## Installation

To install the module, run the following command:

```powershell
Import-Module -Name "C:\github\crowne\FavouriteDirectory\FavouriteDirectory\FavouriteDirectory.psd1"
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