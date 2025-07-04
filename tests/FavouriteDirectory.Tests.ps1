BeforeAll {
    # Import the module being tested
    Import-Module -Name .\FavouriteDirectory\FavouriteDirectory.psd1 -Force

    # Define a temporary path for the test registry in the same directory as the test script
    $script:testRegistryPath = Join-Path -Path $PSScriptRoot -ChildPath "TestFavouriteDirectoryRegistry.json"

    # Mock the Get-FavouriteDirectoryRegistryPath function to use the test path
    Mock -CommandName Get-FavouriteDirectoryRegistryPath -ModuleName FavouriteDirectory -MockWith { return $script:testRegistryPath }
}

AfterAll {
    # Clean up the test registry file
    if (Test-Path -Path $script:testRegistryPath) {
        Remove-Item -Path $script:testRegistryPath -Force
    }
}

Describe 'Favourite Directory Functions' {
    BeforeEach {
        # Ensure a clean test registry file before each test
        Set-Content -Path $script:testRegistryPath -Value "{}" -Force
    }
    Context 'Set-FavouriteDirectory' {
        It 'Should add a new favourite directory' {
            Set-FavouriteDirectory -Name 'test' -Path 'C:\test'
            $registry = Get-Content -Path $script:testRegistryPath -Raw | ConvertFrom-Json -AsHashtable
            $registry['test'] | Should -Be 'C:\test'
        }
    }

    Context 'Get-FavouriteDirectory' {
        It 'Should retrieve an existing favourite directory' {
            Set-FavouriteDirectory -Name 'testget' -Path 'C:\testget'
            $path = Get-FavouriteDirectory -Name 'testget'
            $path | Should -Be 'C:\testget'
        }

        It 'Should return null for a non-existent favourite directory' {
            $path = Get-FavouriteDirectory -Name 'nonexistent'
            $path | Should -BeNull
        }
    }

    Context 'Remove-FavouriteDirectory' {
        It 'Should remove an existing favourite directory' {
            Set-FavouriteDirectory -Name 'testremove' -Path 'C:\testremove'
            Remove-FavouriteDirectory -Name 'testremove'
            $registry = Get-Content -Path $script:testRegistryPath -Raw | ConvertFrom-Json -AsHashtable
            $registry.Keys | Should -Not -Contain 'testremove'
        }

        It 'Should not throw an error for a non-existent favourite directory' {
            { Remove-FavouriteDirectory -Name 'nonexistent' } | Should -Not -Throw
        }
    }

    Context 'Get-FavouriteDirectoryList' {
        It 'Should return all favourite directories' {
            Set-FavouriteDirectory -Name 'test1' -Path 'C:\test1'
            Set-FavouriteDirectory -Name 'test2' -Path 'C:\test2'
            $list = Get-FavouriteDirectoryList
            $list.Count | Should -Be 2
            $list['test1'] | Should -Be 'C:\test1'
            $list['test2'] | Should -Be 'C:\test2'
        }

        It 'Should return an empty hashtable when no favourites are set' {
            $list = Get-FavouriteDirectoryList
            $list.Count | Should -Be 0
        }
    }

    Context 'Invoke-FavouriteDirectory' {
        It 'Should list all favourites with -l' {
            Set-FavouriteDirectory -Name 'test1' -Path 'C:\test1'
            Set-FavouriteDirectory -Name 'test2' -Path 'C:\test2'
            $list = Invoke-FavouriteDirectory -l
            $list.Count | Should -Be 2
        }

        It 'Should get a specific favourite with -l and an argument' {
            Set-FavouriteDirectory -Name 'test1' -Path 'C:\test1'
            $path = Invoke-FavouriteDirectory -l 'test1'
            $path | Should -Be 'C:\test1'
        }

        It 'Should add a favourite with -a' {
            Invoke-FavouriteDirectory -a 'testadd' 'C:\testadd'
            $path = Get-FavouriteDirectory -Name 'testadd'
            $path | Should -Be 'C:\testadd'
        }

        It 'Should delete a favourite with -d' {
            Set-FavouriteDirectory -Name 'testdel' -Path 'C:\testdel'
            Invoke-FavouriteDirectory -d 'testdel'
            $path = Get-FavouriteDirectory -Name 'testdel'
            $path | Should -BeNull
        }

        It 'Should change directory with a default action' {
            Set-FavouriteDirectory -Name 'testcd' -Path $PSScriptRoot
            Invoke-FavouriteDirectory 'testcd'
            $pwd.Path | Should -Be $PSScriptRoot
        }

        It 'Should not allow adding a favourite with a name starting with a hyphen' {
            { Invoke-FavouriteDirectory -a '-invalid' 'C:\invalid' } | Should -Throw
        }

        It 'Should display help with -h' {
            $result = Invoke-FavouriteDirectory -h
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should display help with -help' {
            $result = Invoke-FavouriteDirectory -help
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should list all favourites with no arguments' {
            Set-FavouriteDirectory -Name 'test1' -Path 'C:\test1'
            Set-FavouriteDirectory -Name 'test2' -Path 'C:\test2'
            $list = Invoke-FavouriteDirectory
            $list.Count | Should -Be 2
        }
    }
}
