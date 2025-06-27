# FavoriteDirectory
## Description

A brief description of your project goes here.

## Installation

To install the module, run the following command:

```powershell
Install-Module -Name FavoriteDirectory
```

## Usage

To use the module, first import it:

```powershell
Import-Module -Name FavoriteDirectory
```

Then, you can use the functions in the module.

## Development

### Build

This module does not require a build process.

### Test

Before running the tests, ensure you have the Pester module installed. You can install it with the following command:

```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck
```

To run the tests for the module, run the following command:

```powershell
Invoke-Pester -Path tests/FavoriteDirectory.Tests.ps1
```

### Publish

To publish the module, run the following command:

```powershell
Publish-Module -Name FavoriteDirectory -NuGetApiKey <Your-API-Key>
```

## License

This project is licensed under the MIT License.
