# fromat of the file: Svn__[HostName]_RepoName
# e.g. Svn__devsrc_Payroll
function Read-SvnCredentialFromDisk() {
    param(
        [Parameter(Mandatory = $true)] $RepositoryUrl
    )
    Process {
        $CredentialKey = $RepositoryUrl.Replace('://','__').Replace('/','_')

        $credential = Read-CredentialFromDisk $CredentialKey

        return $credential
    }
}

function Export-Svn ()
{
    param(
        [Parameter(Mandatory = $true)] $ExportPath,
        [Parameter(Mandatory = $true)] $RelativeUrl,
        [Parameter(Mandatory = $true)] $RepositoryUrl,
        $RevisionNo,
        [switch] $CleanFirst,
        $Credential
    )
    Process{
        if ((Test-Path $ExportPath) -and $CleanFirst){
            Write-Host 'Cleaning up the Export directory' $ExportPath '...'
            Remove-Item $ExportPath -Force -Recurse #-Verbose #:($PSBoundParameters['Verbose'] -eq $true)
        }
        if ($Credential -eq $null){
            $Credential = Read-SvnCredentialFromDisk -RepositoryUrl $RepositoryUrl
        }
            
        $url = $RepositoryUrl + $RelativeUrl

        Write-Host 'Performing Svn Export from' $url [Revision:$RevisionNo] 'to' $ExportPath
        
        $password = $Credential.GetNetworkCredential().Password
        $username = $Credential.UserName
        #$arguments = $url, $ExportPath
        
        & svn export $url $ExportPath --quiet --username $username --password $password
        
        if ($LASTEXITCODE -gt 0){
            throw
        }
        Write-Host 'Svn Export finished successfully.'
    }
}

function Export-SvnTag{
    param(
        [Parameter(Mandatory = $true)] $ExportPath,
        [Parameter(Mandatory = $true)] $RelativeUrl,
        [Parameter(Mandatory = $true)] $RepositoryUrl,
        $Credential
    )
    Process {
        Export-Svn -ExportPath $ExportPath -RelativeUrl $RelativeUrl -RepositoryUrl $RepositoryUrl -Credential $Credential -CleanFirst
        #Add the tag info file into the drive
    }
}

function Update-Svn ()
{
    param(
        [Parameter(Mandatory = $true)] $WorkingFolderPath,
        $RepositoryUrl,
        $Credential,
        [Switch] $Quiet,
        [Switch] $IgnoreCredential

        
    )
    Process{
        
        if (!$IgnoreCredential){
            if ($Credential -eq $null){
                $Credential = Read-SvnCredentialFromDisk -RepositoryUrl $RepositoryUrl
            }
            $password = $Credential.GetNetworkCredential().Password
            $username = $Credential.UserName
            $credArgs = '--username ' + $username +' --password ' + $password
        }    
        
        if ($Quiet){
            $quietArg = '--quiet'
        }
        Write-Host Performing Svn Update on $WorkingFolderPath

        & svn update $WorkingFolderPath $quietArg $credArgs
        
        if ($LASTEXITCODE -gt 0){
            throw
        }
        Write-Host 'Svn Update finished successfully.'
    }
}

function Backup-Svn ()
{
    param(
        [Parameter(Mandatory = $true)] $Repository,
        [Parameter(Mandatory = $true)] $BackupTo,
        [Switch] $Quiet
    )
    Process{
        
        if ($Quiet){
            $quietArg = '--quiet'
        }
        Write-Host Backing up [$Repository] to $BackupTo ...

        & svnadmin hotcopy $Repository $BackupTo $quietArg 
        
        if ($LASTEXITCODE -gt 0){
            throw
        }
        Write-Host 'Svn Backup finished successfully.'
    }
}

