
function Invoke-SqlServerCmdByFile (
    $SqlFile, $SqlInstance, $Credential
)
{
    if ($Credential -eq $null){
        $Credential = Read-DbCredentialFromDisk -CredentialKey $SqlInstance -DbType MsSql
    }
    
    Write-Host Executing [$SqlFile] in $SqlInstance ...
    
    Invoke-Sqlcmd -InputFile $SqlFile -ErrorAction 'Stop' -ServerInstance $SqlInstance -Verbose -Username $Credential.UserName -Password $Credential.GetNetworkCredential().Password -QueryTimeout 0
    
    Write-Host 'SQL Server command is executed.'
}

function Invoke-SqlServerCmd {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)] $SqlCommand, 
        [Parameter(Mandatory = $true)] $SqlInstance, 
        $Credential,
        [Switch]$TrustedConnection
    )
    Process {
        if (!$TrustedConnection -and $Credential -eq $null){
            $Credential = Read-DbCredentialFromDisk -CredentialKey $sqlInstance -DbType MsSql
        }
    
        Write-Verbose "Executing command on $sqlInstance ..."
        if ($TrustedConnection){
            Invoke-Sqlcmd -Query $SqlCommand -ErrorAction 'Stop' -ServerInstance $SqlInstance -QueryTimeout 0 -Verbose:($PSBoundParameters['Verbose'] -eq $true) 
        }
        else{
            Invoke-Sqlcmd -Query $SqlCommand -ErrorAction 'Stop' -ServerInstance $SqlInstance -Username $Credential.UserName -Password $Credential.GetNetworkCredential().Password  -QueryTimeout 0 -Verbose:($PSBoundParameters['Verbose'] -eq $true) 
        }
    
        Write-Verbose "SQL command is executed. [$SqlCommand]"
    }
}

function Publish-SqlPackage(){
    param ( 
        [Parameter(Mandatory = $true)] $SqlPackageSourceFile,
        [Parameter(Mandatory = $true)] $SqlPackageProfilePath,
        [Parameter(Mandatory = $true)] $SqlPackageTargetServerName,
        [Parameter(Mandatory = $true)] $SqlPackageTargetDatabaseName,
        $Credential
    )
    process {

        $sqlPackageTool = Join-Path ${env:ProgramFiles(x86)} 'Microsoft SQL Server\110\DAC\bin\Sqlpackage.exe'
        if(!(Test-Path $sqlPackageTool)){
            throw 'Path not found ' + $sqlPackageTool
        }

        if ($Credential -eq $null){
            $Credential = Read-DbCredentialFromDisk -CredentialKey $SqlPackageTargetServerName -DbType MsSql
        }

        Write-Host 'Performing publish' $SqlPackageSourceFile 'into Server:' $SqlPackageTargetServerName # 'Database:' $SqlPackageTargetDatabaseName
        $password = $Credential.GetNetworkCredential().Password
        $username = $Credential.UserName
        
        & $sqlPackageTool /action:Publish /SourceFile:$SqlPackageSourceFile /Profile:$SqlPackageProfilePath /TargetServerName:$SqlPackageTargetServerName /TargetDatabaseName:$SqlPackageTargetDatabaseName /TargetUser:$username /TargetPassword:$password

        if ($LASTEXITCODE -gt 0){
            throw 'Error in deployment of SqlPackages.'
        }
         
    } 
}