
# Copy functions
function Copy-RemoteItemToNet {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)] $srcMachine, 
        [Parameter(Mandatory = $true)] $srcPath, 
        [Parameter(Mandatory = $true)] $desMachine, 
        [Parameter(Mandatory = $true)] $desPath
    )
    Process {

        $desCred = Read-CredentialFromDisk $desMachine
    
        Invoke-ScriptBlock -ComputerName $srcMachine -CommandTitle 'Copying items to Network drive' -Arguments $srcPath,$desCred,$desPath -ScriptBlock {
            param($srcPath, $desCred, $desPath)
        
            $letter = "Z"
            New-PSDrive -Name $letter -Root $desPath -PSProvider FileSystem -Credential $desCred

            $driveLetter =$letter + ':\'
            Copy-Item $srcPath $driveLetter -Force -Verbose
        
            #Clean up the Mapped network drive by deleting the PSDrive
            Remove-PSDrive -Name $letter -Verbose:($PSBoundParameters['Verbose'] -eq $true)
        }
    }
}


function Copy-RemoteItemLocally {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)] $computerName, 
        [Parameter(Mandatory = $true)] $srcPath, 
        [Parameter(Mandatory = $true)] $desPath
    )
    Process {
        Invoke-ScriptBlock -ComputerName $computerName -CommandTitle 'Copying items locally' -Arguments $srcPath,$desPath -ScriptBlock {
            param($srcPath, $desPath)
            Copy-Item $srcPath $desPath -Force -Verbose
        }
    }
}

function Copy-ItemToRemoteComputer (){
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)] $ComputerName, 
        [Parameter(Mandatory = $true)] $SrcPath, 
        [Parameter(Mandatory = $true)] $DesRemotePath, 
        $Credential, 
        [switch]$CleanFirst
    )
    Process {
        try {
            if ($credential -eq $null){
                $credential = Read-CredentialFromDisk $computerName
            }
            
            #Create the folder if it's not exist or clean it up if requested.
            Invoke-ScriptBlock -ComputerName $computerName -Arguments ($PSBoundParameters['Verbose'] -eq $true), $DesRemotePath, $CleanFirst -Credential $Credential -ScriptBlock {
                param($verbose, $RemotePath, $cleanFirst)
               
                if (!(Test-Path $RemotePath)){
                    New-Item $RemotePath -ItemType directory -Verbose:($verbose -eq $true)
                } 
                #Clean up the destination folder if it's been requested.
                elseif ($cleanFirst){
                    
                    $cleaningPath = Join-Path $RemotePath '*'
                    Write-Host $cleaningPath
                    Remove-Item $cleaningPath -Force -Recurse -Verbose:($verbose -eq $true)
                }
            } 
            
            $letter = "Z"
            $drive = $letter + ':\'
            $uncPath = '\\' + $computerName + '\' + $desRemotePath.Replace(":","$")
            
            #Create a mapped netwerk drive
            New-PSDrive -Name $letter -Root $uncPath -PSProvider FileSystem -Credential $credential -Verbose:($PSBoundParameters['Verbose'] -eq $true)
            #Write-Host 'Connected to' $uncPath
            
            Write-Host 'Copying from' $srcPath 'to' $uncPath
            #Copy the files from source to the destination path
            Copy-Item $srcPath $drive -Force -Recurse -Verbose:($PSBoundParameters['Verbose'] -eq $true) -ErrorAction Stop 
            
            #& dir 
            #Start-Sleep 30

            #Clean up the Mapped network drive by deleting the PSDrive
            Remove-PSDrive -Name $letter -Verbose:($PSBoundParameters['Verbose'] -eq $true)

            #Write-Host 'Disconnected from' $uncPath

        } catch {
            throw 
        } 
    }
}

#GAC functions
function Install-AssemblyToRemoteGAC (){
    param (
        $AssembliesPath,
        [Parameter(Mandatory = $true)] $ComputerName,
        $RemoteAssembliesPath,
        $Credential
    )
     Process{
        if ($RemoteAssembliesPath -eq $null){
            #Obtain the TEMP folder path in the remote machine
            $RemoteAssembliesPath = Invoke-ScriptBlock -ComputerName $ComputerName -CommandTitle 'Getting TEMP directory'  -scriptBlock {
                    return Get-Item $env:TEMP
            }
            $RemoteAssembliesPath =  Join-Path $RemoteAssembliesPath.FullName  'PsUtilGacInstallation'
        }
         
        if ($AssembliesPath -ne $null) {
                #Copy the assembly to the Remote Machine in Temp folder 
                           
                Copy-ItemToRemoteComputer -computerName $ComputerName -srcPath $AssemblyPath -desRemotePath $RemoteAssembliesPath -CleanFirst
            
        }
        
        Import-Module PsUtil.Common
        $sb = Get-Command | Where  {$_.Name -EQ 'Install-AssemblyToGAC' -and $_.CommandType -eq 'Function' }
        Invoke-ScriptBlock -ComputerName $ComputerName -Arguments $RemoteAssembliesPath -CommandTitle 'Installing assemblies to GAC' -ScriptBlock $sb.ScriptBlock 

    }
}



