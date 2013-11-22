param (
    $CredentialKey
)


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
