# FavoriteDirectory

A PowerShell module to manage favorite directory aliases.
This module was written using Gemini cli and claude-code as a learning kata for me to become familiar with the ai code tools.

## Installation

To install the module, run the following command:

```powershell
Import-Module -Name "C:\github\crowne\FavoriteDirectory\FavoriteDirectory\FavoriteDirectory.psd1"
```

## Usage

### Add a favorite directory

```powershell
fd -a <name> <path>
```

### List favorite directories

```powershell
fd -l
```

### Get a favorite directory

```powershell
fd -l <name>
```

### Remove a favorite directory

```powershell
fd -d <name>
```

### Go to a favorite directory

```powershell
fd <name>
```