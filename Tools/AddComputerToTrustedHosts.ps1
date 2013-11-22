param (
    $HostName
)


#show the Trusted hosts
Get-Item wsman:\localhost\client\TrustedHosts

#get the new host
$HostName = Read-Host 'What is the trusted host IP address?(Press blank enter to exit)'
if ($HostName -eq ''){
    return;
}
   

Add-ComputerToTrustedHosts $HostName

Write-Host 'Default Credential Directory (env:PSCredentialPath) is:' $env:PSCredentialPath
#Capture the credential
Save-CredentialToDisk -CredentialKey $HostName

