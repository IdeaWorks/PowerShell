
function Read-CredentialFromDisk($CredentialKey){
    #$credRootPath
    $CredentialKey = $CredentialKey +'.ps1.credential'
    $credPath = Join-Path $env:PSCredentialPath $CredentialKey
    #$credPath
    $credential = Import-CliXml $credPath

    #return @(,$credential)
    return $credential
}



function Save-CredentialToDisk{
    Param (
        [Parameter(Mandatory = $true)] $CredentialKey
    )
    Process{
        try {

            $cred = Get-Credential
        
            $CredentialKeyFile = $CredentialKey +'.ps1.credential'
            $credPath = Join-Path $env:PSCredentialPath $CredentialKeyFile

            $cred | Export-CliXml $credPath
            Write-Host [$credPath] is created.

            $credential = Read-CredentialFromDisk $CredentialKey

            Add-Type –AssemblyName System.Windows.Forms
            [System.Windows.Forms.MessageBox]::Show(
                "Username= " + $credential.UserName + "    Password= " + $credential.GetNetworkCredential().Password)
   
        } catch {
            throw
        }
    }
}


function Read-DbCredentialFromDisk() {
    Param(
        [Parameter(Mandatory = $true)] $CredentialKey,
        [ValidateSet("MsSql")] [Parameter(Mandatory = $true)] $DbType
    )
    Process{
        $CredentialKey =  $CredentialKey.Replace("\","_") + "__" + $DbType
        $credential = Read-CredentialFromDisk -CredentialKey $CredentialKey
        return $credential
    }
}



function Add-ComputerToTrustedHosts($hostName){
    
    $trustedHosts = Get-Item wsman:\localhost\client\TrustedHosts
    
    if ($trustedHosts.Value.Contains($hostName)){
        Write-Host $hostName + " is already exists"
        return
         
    }

    if ($trustedHosts.Value -ne ''){
        $trustedHosts.Value += ","
    }

    $trustedHosts.Value += $hostName

    Set-Item wsman:\localhost\client\TrustedHosts $trustedHosts.Value

    Get-Item wsman:\localhost\client\TrustedHosts
    
}


# We can introduce a new function to return the plain user/pass (for using in sqlcmd or other thirdparty commands)

