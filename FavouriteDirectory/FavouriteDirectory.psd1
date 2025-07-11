@{
    RootModule = 'FavouriteDirectory.psm1'
    ModuleVersion = '0.0.6'
    GUID = 'e0c6e7a8-17a9-4e2a-8b6b-5b6a5f3e6e1d' # This will be populated with a unique GUID
    Author = 'Neil Crow'
    CompanyName = 'Crowne'
    Copyright = '(c) 2025 Crowne. All rights reserved.'
    Description = 'A PowerShell module to manage favourite directory aliases.'
    PowerShellVersion = '5.1'
    DotNetFrameworkVersion = '4.5.2'
    RequiredModules = @()
    AliasesToExport = 'fd'
    PrivateData = @{
        PSData = @{
            ProjectUri = 'https://github.com/crowne/FavouriteDirectory'
            LicenseUri = 'https://opensource.org/license/mit/'
            Tags = @('PowerShell', 'FavouriteDirectory', 'Alias', 'Module')
            ReleaseNotes = 'Initial release of FavouriteDirectory module.'
        }
    }
}