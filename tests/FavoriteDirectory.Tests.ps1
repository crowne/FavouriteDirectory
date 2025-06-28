BeforeAll {
    # Import the module being tested
    Import-Module -Name .\FavoriteDirectory\FavoriteDirectory.psd1 -Force

    # Define a temporary path for the test registry in the same directory as the test script
    $script:testRegistryPath = Join-Path -Path $PSScriptRoot -ChildPath "TestFavoriteDirectoryRegistry.json"

    # Mock the Get-FavoriteDirectoryRegistryPath function to use the test path
    Mock -CommandName Get-FavoriteDirectoryRegistryPath -ModuleName FavoriteDirectory -MockWith { return $script:testRegistryPath }
}

AfterAll {
    # Clean up the test registry file
    if (Test-Path -Path $script:testRegistryPath) {
        Remove-Item -Path $script:testRegistryPath -Force
    }
}

Describe 'Favorite Directory Functions' {
    BeforeEach {
        # Ensure a clean test registry file before each test
        Set-Content -Path $script:testRegistryPath -Value "{}" -Force
    }
    Context 'Set-FavoriteDirectory' {
        It 'Should add a new favorite directory' {
            Set-FavoriteDirectory -Name 'test' -Path 'C:\test'
            $registry = Get-Content -Path $script:testRegistryPath -Raw | ConvertFrom-Json -AsHashtable
            $registry['test'] | Should -Be 'C:\test'
        }
    }

    Context 'Get-FavoriteDirectory' {
        It 'Should retrieve an existing favorite directory' {
            Set-FavoriteDirectory -Name 'testget' -Path 'C:\testget'
            $path = Get-FavoriteDirectory -Name 'testget'
            $path | Should -Be 'C:\testget'
        }

        It 'Should return null for a non-existent favorite directory' {
            $path = Get-FavoriteDirectory -Name 'nonexistent'
            $path | Should -BeNull
        }
    }

    Context 'Remove-FavoriteDirectory' {
        It 'Should remove an existing favorite directory' {
            Set-FavoriteDirectory -Name 'testremove' -Path 'C:\testremove'
            Remove-FavoriteDirectory -Name 'testremove'
            $registry = Get-Content -Path $script:testRegistryPath -Raw | ConvertFrom-Json -AsHashtable
            $registry.Keys | Should -Not -Contain 'testremove'
        }

        It 'Should not throw an error for a non-existent favorite directory' {
            { Remove-FavoriteDirectory -Name 'nonexistent' } | Should -Not -Throw
        }
    }

    Context 'Get-FavoriteDirectoryList' {
        It 'Should return all favorite directories' {
            Set-FavoriteDirectory -Name 'test1' -Path 'C:\test1'
            Set-FavoriteDirectory -Name 'test2' -Path 'C:\test2'
            $list = Get-FavoriteDirectoryList
            $list.Count | Should -Be 2
            $list['test1'] | Should -Be 'C:\test1'
            $list['test2'] | Should -Be 'C:\test2'
        }

        It 'Should return an empty hashtable when no favorites are set' {
            $list = Get-FavoriteDirectoryList
            $list.Count | Should -Be 0
        }
    }
}
