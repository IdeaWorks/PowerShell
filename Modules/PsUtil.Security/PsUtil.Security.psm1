
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




function Protect-Data{
    Param(
        [Parameter(Mandatory = $true)] $PlainData,
        [ValidateSet("UTF8", "ByteArray")] $InputType = "UTF8",
        [ValidateSet("CurrentUser","LocalMachine")] $Scope = "CurrentUser",
        [ValidateSet("Base64String", "ByteArray")] $OutputType = "Base64String"
    )
    Process{
        $protectionScope = $protectionScope = [System.Security.Cryptography.DataProtectionScope]::CurrentUser
        if ($Scope -eq "LocalMachine"){
            $protectionScope = [System.Security.Cryptography.DataProtectionScope]::LocalMachine
        }
        $plainBytes = Convert-Data -InputData $PlainData -InputType $InputType -OutputType ByteArray
        
        $cipher = [System.Security.Cryptography.ProtectedData]::Protect($plainBytes, $null, $protectionScope)
        
        $result = Convert-Data -InputData $cipher -InputType ByteArray -OutputType $OutputType
        
        return $result
    }
}

function Unprotect-Data{
    Param(
        [Parameter(Mandatory = $true)]$CipherData,
        [ValidateSet("Base64String", "ByteArray")] $InputType = "Base64String",
        [ValidateSet("CurrentUser","LocalMachine")] $Scope = "CurrentUser",
        [ValidateSet("UTF8", "ByteArray")] $OutputType = "UTF8"
    )
    Process{
        $protectionScope = $protectionScope = [System.Security.Cryptography.DataProtectionScope]::CurrentUser
        if ($Scope -eq "LocalMachine"){
            $protectionScope = [System.Security.Cryptography.DataProtectionScope]::LocalMachine
        }

        $cipherBytes = Convert-Data -InputData $CipherData -InputType $InputType -OutputType ByteArray

        $plainBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($cipherBytes, $null, $protectionScope)

        $result = Convert-Data -InputData $plainBytes -InputType ByteArray -OutputType $OutputType

        return $result
    }
}