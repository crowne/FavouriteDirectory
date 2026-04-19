#Requires -modules  @{ ModuleName="Pester"; ModuleVersion="5.7.1" }

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

    Context 'Get-FavouriteDirectoryGitStatus' {
        It 'Should return null when git is not installed' {
            Mock -CommandName Get-Command -ModuleName FavouriteDirectory -ParameterFilter { $Name -eq 'git' } -MockWith { return $null }
            $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
            $result = Get-FavouriteDirectoryGitStatus -Path $repoRoot
            $result | Should -BeNull
        }

        It 'Should return null for a non-existent path' {
            $result = Get-FavouriteDirectoryGitStatus -Path 'C:\nonexistent_path_xyz_123'
            $result | Should -BeNull
        }

        It 'Should return null for a path that is not a git repository' {
            $result = Get-FavouriteDirectoryGitStatus -Path $env:TEMP
            $result | Should -BeNull
        }

        It 'Should return an object with a Branch property for a valid git repository' {
            $repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
            $result = Get-FavouriteDirectoryGitStatus -Path $repoRoot
            $result | Should -Not -BeNull
            $result.Branch | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain 'Staged'
            $result.PSObject.Properties.Name | Should -Contain 'Unstaged'
            $result.PSObject.Properties.Name | Should -Contain 'Untracked'
        }
    }

    Context 'Show-FavouriteDirectoryList' {
        It 'Should output a line containing the name and path for a non-git directory' {
            Set-FavouriteDirectory -Name 'tmpdir' -Path $env:TEMP
            $output = Show-FavouriteDirectoryList
            $line = $output | Where-Object { $_ -match 'tmpdir' }
            $line | Should -Not -BeNullOrEmpty
            $line | Should -Match $env:TEMP.Replace('\', '\\')
            $line | Should -Not -Match '\['
        }

        It 'Should output a line with a git branch indicator for a git repository' {
            $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
            Set-FavouriteDirectory -Name 'repofav' -Path $repoRoot
            $output = Show-FavouriteDirectoryList
            $line = $output | Where-Object { $_ -match 'repofav' }
            $line | Should -Not -BeNullOrEmpty
            $line | Should -Match '\['
        }

        It 'Should return a single line when -Name is specified' {
            Set-FavouriteDirectory -Name 'singletest' -Path $env:TEMP
            $output = Show-FavouriteDirectoryList -Name 'singletest'
            $lines = @($output | Where-Object { $_ -match '\S' })
            $lines.Count | Should -Be 1
        }

        It 'Should display a message when no favourites are registered' {
            Set-Content -Path $script:testRegistryPath -Value "{}" -Force
            $output = Show-FavouriteDirectoryList
            $output | Should -Match 'No favourite'
        }
    }

    Context 'Invoke-FavouriteDirectory' {
        It 'Should list all favourites with -l' {
            Set-FavouriteDirectory -Name 'test1' -Path 'C:\test1'
            Set-FavouriteDirectory -Name 'test2' -Path 'C:\test2'
            $list = Invoke-FavouriteDirectory -l
            ($list | Where-Object { $_ -match 'test1' }) | Should -Not -BeNullOrEmpty
            ($list | Where-Object { $_ -match 'test2' }) | Should -Not -BeNullOrEmpty
        }

        It 'Should get a specific favourite with -l and an argument' {
            Set-FavouriteDirectory -Name 'test1' -Path 'C:\test1'
            $output = Invoke-FavouriteDirectory -l 'test1'
            $output | Should -Match 'test1'
            $output | Should -Match 'C:\\test1'
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
            ($list | Where-Object { $_ -match 'test1' }) | Should -Not -BeNullOrEmpty
            ($list | Where-Object { $_ -match 'test2' }) | Should -Not -BeNullOrEmpty
        }
    }
}
