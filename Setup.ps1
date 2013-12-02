#Importing the required module in order to runt the setup
Write-Host 'Importing modules...'
$psModules = Join-Path $PSScriptRoot 'Modules\PsUtil.Common'
Import-Module -Name $psModules

#Add PSModules into the PSModulePath
Write-Host 'Adding modules to the PSModulePath Environment Varaible...'
$modules = Join-Path $PSScriptRoot 'Modules\'
Set-EnvVariable -EnvVariable 'PSModulePath' -Value $modules -VariableType Path -Verbose
$credPath = 'C:\PsCredentials'

#Add PSCredntialPath in order to store the credentials (if any)
Write-Host 'Adding credential paths to the Environment Varaible...'
$credPathInput = Read-Host The default credentials path is [$credPath] Press enter if it is OK or type another path
if ($credPathInput -eq ''){
    $credPathInput = $credPath
}

Set-EnvVariable -EnvVariable 'PSCredentialPath' -Value $credPathInput -VariableType Path -Overwrite -Verbose

