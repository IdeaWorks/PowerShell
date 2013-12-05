param (
    $CredentialKey
)

Write-Host Format for database credential is HostName_InstanceName__DBType -foregroundcolor Green
Write-Host MS SQL instances: 1.2.3.4_MyInstance__MsSql -foregroundcolor Green
Write-host Or for one instance in the machine: 1.2.3.4__MsSql -foregroundcolor Green

Write-Host 'Default Credential Directory (env:PSCredentialPath) is:' $env:PSCredentialPath

if ($CredentialKey -eq $null){

    $CredentialKey = Read-Host 'What is the Credential Key for? (Press blank enter to exit)'
    if ($CredentialKey -eq ''){
        return;
    }
}



Save-CredentialToDisk -CredentialKey $CredentialKey

#Write-Host($cred.GetType())
#$cred.UserName
#$cred.GetNetworkCredential().Password  
