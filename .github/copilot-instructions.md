# Copilot Instructions

## Project Overview

`FavouriteDirectory` is a PowerShell module (published to PowerShell Gallery) that manages named directory aliases via a single `fd` alias command. The module targets PowerShell 5.1+.

## Architecture

All user-facing functionality flows through `Invoke-FavouriteDirectory` (aliased as `fd`), which dispatches to internal functions based on positional `$args` (not declared parameters — the function uses `param()` empty and reads `$args` directly).

Persistence is a JSON hashtable stored at:
`$env:APPDATA\FavouriteDirectory\FavouriteDirectoryRegistry.json`

The registry path is always obtained via `Get-FavouriteDirectoryRegistryPath`, which is mocked in tests. Registry entries are always saved alphabetically sorted via `Save-FavouriteDirectoryRegistry`.

**Module files:**
- `FavouriteDirectory/FavouriteDirectory.psm1` — all functions and the `fd` alias
- `FavouriteDirectory/FavouriteDirectory.psd1` — manifest; bump `ModuleVersion` before publishing
- `tests/FavouriteDirectory.Tests.ps1` — Pester 5.7.1 test suite

## Testing

Install Pester first (one-time):
```powershell
Install-Module Pester -RequiredVersion 5.7.1 -Force -SkipPublisherCheck
```

Run the full test suite (must run from repo root):
```powershell
pwsh -NoProfile .\tests\FavouriteDirectory.Tests.ps1
```

Run a single test by name:
```powershell
pwsh -NoProfile -Command "Invoke-Pester .\tests\FavouriteDirectory.Tests.ps1 -FullNameFilter '*Should add a new favourite directory*'"
```

Tests use `Mock -CommandName Get-FavouriteDirectoryRegistryPath -ModuleName FavouriteDirectory` to redirect registry I/O to a temp file (`tests/TestFavouriteDirectoryRegistry.json`), which is cleaned up in `AfterAll`.

## Key Conventions

- **Flag pairs**: every action has a short and long form (e.g. `-a`/`-add`, `-d`/`-delete`, `-l`/`-list`). Both must be handled in the `switch` in `Invoke-FavouriteDirectory`.
- **Name validation**: directory alias names must not start with `-` (enforced in `Set-FavouriteDirectory`).
- **No declared parameters in `Invoke-FavouriteDirectory`**: it uses `param()` + `$args` so it can act as a pass-through alias. Do not add `[Parameter(...)]` attributes to it.
- **All functions use `[CmdletBinding()]`** and include comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.INPUTS`, `.OUTPUTS`).
- **Export everything public** via `Export-ModuleMember` at the bottom of the `.psm1`.

## Before Committing Changes

Always bump `ModuleVersion` in `FavouriteDirectory/FavouriteDirectory.psd1` when making any functional change.

## Publishing Pre-flight

```powershell
Test-ModuleManifest .\FavouriteDirectory\FavouriteDirectory.psd1
Publish-Module -Path ./FavouriteDirectory -NuGetApiKey $secret -WhatIf -Verbose
```

CI publishing is triggered by a GitHub Release and uses the `NUGET_API_KEY` repository secret.
