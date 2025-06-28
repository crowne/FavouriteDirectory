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

    Context 'Invoke-FavoriteDirectory' {
        It 'Should list all favorites with -l' {
            Set-FavoriteDirectory -Name 'test1' -Path 'C:\test1'
            Set-FavoriteDirectory -Name 'test2' -Path 'C:\test2'
            $list = Invoke-FavoriteDirectory -Action '-l'
            $list.Count | Should -Be 2
        }

        It 'Should get a specific favorite with -l and an argument' {
            Set-FavoriteDirectory -Name 'test1' -Path 'C:\test1'
            $path = Invoke-FavoriteDirectory -Action '-l' -Arguments 'test1'
            $path | Should -Be 'C:\test1'
        }

        It 'Should add a favorite with -a' {
            Invoke-FavoriteDirectory -Action '-a' -Arguments 'testadd', 'C:\testadd'
            $path = Get-FavoriteDirectory -Name 'testadd'
            $path | Should -Be 'C:\testadd'
        }

        It 'Should delete a favorite with -d' {
            Set-FavoriteDirectory -Name 'testdel' -Path 'C:\testdel'
            Invoke-FavoriteDirectory -Action '-d' -Arguments 'testdel'
            $path = Get-FavoriteDirectory -Name 'testdel'
            $path | Should -BeNull
        }

        It 'Should change directory with a default action' {
            Set-FavoriteDirectory -Name 'testcd' -Path $PSScriptRoot
            Invoke-FavoriteDirectory -Action 'testcd'
            $pwd.Path | Should -Be $PSScriptRoot
        }

        It 'Should not allow adding a favorite with a name starting with a hyphen' {
            { Invoke-FavoriteDirectory -Action '-a' -Arguments '-invalid', 'C:\invalid' } | Should -Throw
        }

        It 'Should display help with -h' {
            $result = Invoke-FavoriteDirectory -Action '-h'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should display help with -help' {
            $result = Invoke-FavoriteDirectory -Action '-help'
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
