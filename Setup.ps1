try {
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

    #Create a shortcut for the command execution
    Write-Host 'Adding Desktop Shortcut...'
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\IdeaWorks PowerShell.lnk")
    $Shortcut.TargetPath = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
    $Shortcut.Arguments =  '-ExecutionPolicy bypass'
    $Shortcut.WorkingDirectory = $PSScriptRoot
    $Shortcut.Save()
    
}catch{
    throw
}

Write-Host "Setup was Successful"
