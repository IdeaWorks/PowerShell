
#function Test-Echo($msg){
#    Write-Host $msg 'Echoed'
#}


#Function Invocation

function Resolve-Function ($funcName, $contextCmds){
    $sb = $contextCmds | Where  {$_.Name -EQ $funcName -and $_.CommandType -eq 'Function' } 
    #Write-Host $sb.ScriptBlock
    if ($sb -eq $null){
        throw 'Function [' +$funcName +'] not found!'
    }
    return $sb.ScriptBlock
}

function Invoke-FunctionByName ($funcName, $contextCmds){
    $sb = Resolve-Function $funcName $contextCmds
    invoke-command -scriptblock $sb    
}

function Invoke-FunctionsByName ($funcNames, $contextCmds){
    
    # Execute the Function by name 
    if (!$funcNames.GetType().IsArray){
        Invoke-FunctionByName $funcNames $contextCmds
        return
    }

    #If the funcNames is array of names then loop through them and execute them one by one
    for ($i = 0; $i -le $funcNames.Length; $i ++){
        if ($funcNames[$i] -eq $null){
            continue
        }
        #Write-Host '['$funcList[$i]'] is executing...'
        Invoke-FunctionByName $funcNames[$i] $contextCmds 
    }
}

#Invokeing Commands
function Invoke-ScriptBlock
{
   [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] $ScriptBlock,
        $ComputerName,
        $CommandTitle,
        $Credential,
        $Arguments
    )
    Process{
        if ($CommandTitle -ne $null){
            $CommandTitle = ' [' + $CommandTitle + ']'
        }
        if($ComputerName -eq $null){
            Write-Host Performing command$CommandTitle in local machine ...
            $output = Invoke-Command -ArgumentList $Arguments -ScriptBlock $ScriptBlock -Verbose:($PSBoundParameters['Verbose'] -eq $true)
        }else{
            if ($Credential -eq $null){
                $Credential =  Read-CredentialFromDisk -CredentialKey $ComputerName
            }
            Write-Host Performing command$CommandTitle in computer [$ComputerName] ...
            $output = Invoke-Command -ComputerName $ComputerName -ArgumentList $Arguments -Credential $Credential  -ScriptBlock $ScriptBlock -Verbose:($PSBoundParameters['Verbose'] -eq $true)
        }
        return $output
    }
    
}

#GAC Functions

function Install-AssemblyToGAC(){
    param (
        [Parameter(Mandatory = $true)] $AssembliesPath
    )
     Process{
        $gacUtil = Join-Path $env:NETFX4Tools 'gacutil.exe'
        if (!(Test-Path $gacUtil)){
            throw $gacUtil + ' is not exist.'
        }
        $assemblies = Get-ChildItem $AssembliesPath -Recurse -Filter *.dll
        if ($assemblies.Count -eq 0){
            throw "No assembly found to install."
        }

        $assemblies | ForEach-Object {
            Write-Host 'Installing' $_.FullName 'into GAC...'

            & $gacUtil /i $_.FullName
                
            if ($LASTEXITCODE -gt 0){
                throw 'Error in installation of ' + $AssembliesPath +' to the GAC.'
            }
        }
    }
}

#Compression

function Compress-Item(){
    param(
        [Parameter(Mandatory = $true)] $ArchivePath,
        [Parameter(Mandatory = $true)] $SourcePath,
        [switch] $TestArchiveFile,
        [switch] $NewArchive
    )
    Process{
        $7zipTool = Join-Path $env:ProgramFiles '7-Zip\7z.exe'

        $sw = [Diagnostics.Stopwatch]::StartNew()
        if(Test-Path $ArchivePath){
            Remove-Item $ArchivePath -Recurse -Force -Verbose
        }
        
        
        Write-Host 'Compressing' $SourcePath 'to' $ArchivePath
        

        & $7zipTool a -t7z $ArchivePath $SourcePath #'-oD:\Environments\Decompress'        
        if ($LASTEXITCODE -gt 0){
            throw 
        }

        $sw.Stop()
        Write-Host 'Operation Time:' $sw.Elapsed.Hours':'$sw.Elapsed.Minutes':'$sw.Elapsed.Seconds 
    }
}

function Expand-Item(){
    param(
        [Parameter(Mandatory = $true)] $ArchivePath,
        [Parameter(Mandatory = $true)] $DestinationPath,
        $CleanFirst
    )
    Process{
        $7zipTool = Join-Path $env:ProgramFiles '7-Zip\7z.exe'
        
        $sw = [Diagnostics.Stopwatch]::StartNew()
        if((Test-Path $DestinationPath) -and $CleanFirst ){
            Write-Host 'Cleaning up...'
            Remove-Item $DestinationPath -Recurse -Force
        }

        Write-Host 'Extracting' $ArchivePath 'to' $DestinationPath

        $DestinationPath = '-o' + $DestinationPath
        & $7zipTool x $ArchivePath $DestinationPath -aoa #'-oD:\Environments\Decompress'        
        if ($LASTEXITCODE -gt 0){
            throw 
        }

        $sw.Stop()
        Write-Host 'Operation Time:' $sw.Elapsed.Hours ':' $sw.Elapsed.Minutes ':' $sw.Elapsed.Minutes 
    }

}

#Windows Service

function Invoke-WinServiceCommand{
    Param(
        [Parameter(Mandatory = $true)] $Name,
        [ValidateSet("Stop", "Start", "Restart")] $CommandType,
        $ComputerName,
        $Credential
    )
    Process{
        $sb = {
                Param($Name,$CommandType)
                if (!(Get-Service $Name -ErrorAction SilentlyContinue))
                {
                    throw 'ERROR: Service [' + $Name + '] not found.'
                }
                switch ($CommandType){
                    Restart {
                        Restart-Service -Name $Name -Force -Verbose
                    }

                    Stop {
                        Stop-Service -Name $Name -Force -Verbose
                        <# Another version...                        

                        $service = Get-WmiObject -query "Select * from Win32_Service where name='$Name'"
                        Write-Host "stopping the $Name service now ..." 
                        $rtn = $service.stopService()
                        Write-Host return value : $rtn.returnvalue
                        Switch ($rtn.returnvalue) 
                        { 
                            0 { Write-Host -foregroundcolor green "$Name stopped" }
                            2 { throw "$Name service reports access denied" }
                            5 { throw "$Name service cannot accept control at this time" }
                            10 { Write-Host -ForegroundColor red "$Name service is already stopped" }
                            DEFAULT { throw "$Name service reports ERROR $($rtn.returnValue)" }
                        }
                        #>
                    }
                                            
                    Start {
                        Start-Service -Name $Name -Verbose
                    }
                }
                #Start-Sleep -Seconds 5
                $status = Get-Service $Name | select Status
                Write-Host Service status is $status
            }
        
        Invoke-ScriptBlock -ScriptBlock $sb -Arguments $Name,$CommandType -ComputerName $ComputerName -CommandTitle "$CommandType-Service"

    }
}

function Install-WinService{
    Param(
        [Parameter(Mandatory = $true)] $Name,
        [Parameter(Mandatory = $true)] $ServicePath,
        $Description = ' ',
        $DisplayName = $Name,
        $ComputerName,
        $Credential,
        [ValidateSet("Automatic", "Manual", "Disabled")] $StartupType = 'Automatic',
        $StartRetryAttempts = 3
        
    )
    Process{

        $sb = {
                Param($Name,$ServicePath,$StartupType,$DisplayName,$Description,$StartRetryAttempts )
                try {

                    Write-Host Installing service [$Name] ...
                    #Create the new service
                    New-Service -Name $Name -BinaryPathName $ServicePath -StartupType $StartupType -Verbose -DisplayName $DisplayName -Description $Description
                    
                    #Start the new service
                    for ($i = 1; $i -le $StartRetryAttempts; $i++){
                        Write-Host Trying to start the service [$Name] Attempt $i ...
                        Start-Service -Name $Name -Verbose -ErrorAction SilentlyContinue
                        #Test the new service
                        $service = Get-Service | Where-Object {$_.Name -eq $Name -and $_.status -eq "running"}
                        if ($service -ne $null){
                            break;
                        }
                    }
                    
                    if ($i -gt $StartRetryAttempts){
                        throw 'Service cannot be started.'
                    }

                    Write-Host Service [$Name] has been successfully installed.

                } catch {
                    throw
                }
            }
        Invoke-ScriptBlock -ComputerName $ComputerName -CommandTitle 'Installing Windows Service' -ScriptBlock $sb `
            -Arguments $Name,$ServicePath,$StartupType,$DisplayName,$Description,$StartRetryAttempts
            
        
    }

}

function Uninstall-WinService{
    Param(
        [Parameter(Mandatory = $true)] $Name,
        [Parameter(Mandatory = $true)] $ServiceFolderPath,
        [Switch] $CleanServiceFolder,
        $ComputerName,
        $Credential,
        $RetryAttempts = 10
        
    )
    Process{

        $sb = {
                Param($Name,$RetryAttempts,$ServiceFolderPath,$CleanServiceFolder )
                try {
                    #Check if the service exists 
                    if (Get-Service $Name -ErrorAction SilentlyContinue) 
                    { 
                        Write-Host Stopping service [$Name] ...
                        Stop-Service -Name $Name -Force -Verbose
                        
                        Write-Host Removing service [$Name] ...
                        $removingService = Get-WmiObject -query "Select * from Win32_Service where name='$Name'"
                        if ($removingService -eq $null){
                            throw "Service $Name cannot be found."
                        }
                        $removingService.delete() 
                        Write-Host Service [$Name] has been successfully removed. 

                    }
                    
                    if ($CleanServiceFolder){
                        Write-Host Cleaning the service folder [$ServiceFolderPath] ...
                        $counter = 1
                        do
                        {
                            Write-Host Trying to clean. Attempt $counter ...
                            Remove-Item $ServiceFolderPath -Force -Recurse -ErrorAction SilentlyContinue
                            Start-Sleep -Seconds 2
                            
                            if (!(Test-Path $ServiceFolderPath -ErrorAction Continue)){
                                break
                            }
                            $counter++
                            #Start-Sleep -Seconds 2
                        
                        } while ($counter-le $RetryAttempts)
                    
                        if ($counter -gt $RetryAttempts){
                            throw 'Cannot clean the service folder ' + $ServiceFolderPath
                        }
                    }


                } catch {
                    throw
                }
            }

        Invoke-ScriptBlock -ScriptBlock $sb -Arguments $Name,$RetryAttempts,$ServiceFolderPath,$CleanServiceFolder -ComputerName $ComputerName -CommandTitle 'Uninstalling Windows Service'
    }

}


#Mail Services 

function Send-NotificationEmail ($subject, $body, $recipients, $credRootPath, $credential){

    Write-Host "Sending Notification Email..."

    $from = "t2p.notify@gmail.com"
    $smtpServer = "smtp.gmail.com"
    $smtpPort = "587"
    #$userName = "t2p.notify@gmail.com"
    #$password = "esst2pweb2"
    if ($subject -eq ''){
        $subject = "Automated Email From Powershell"
    }
    
    if ($credential -eq $null){
        $credential = Read-CredentialFromDisk -CredentialKey $from -credRootPath $credRootPath        
    }


    Send-MailMessage -From $from -To $recipients -Subject $subject -Body $body -SmtpServer $smtpServer -Port $smtpPort -UseSsl -Credential $cred
  
}

#MSBuild 
function Invoke-MSBuild{
    Param (
        [Parameter(Mandatory = $true)] $ProjectFile,
        $Properties,
        $Targets
    )
    Process{
        $msBuildTool = Join-Path $env:windir 'Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe'

        & $msBuildTool $ProjectFile /p:$Properties /t:$Targets
        if ($LASTEXITCODE -gt 0){
            throw 'ERROR in building project ' + $ProjectFile
        }
    }
}