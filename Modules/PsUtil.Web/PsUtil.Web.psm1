function Get-IISWebSitePhysicalPath(){
    param(
        $ComputerName,
        $WebSiteName
    )
    Process{
        $item = Get-IISWebItem -ComputerName $computerName -Name $WebSiteName
        $physicalPath = $item.PhysicalPath
        return $physicalPath
    }
}

function Get-IISWebApplication(){
    param(
        $ComputerName,
        [Parameter(Mandatory = $true)]$Name
    )
    
    $webApp = Invoke-ScriptBlock -ComputerName $ComputerName -Arguments $Name -scriptBlock {
        param($name)
        #Import-Module WebAdministration
        $res = Get-WebApplication -Name $name | select *
        $res.PhysicalPath = $res.PhysicalPath.Replace("%SystemDrive%", $env:SystemDrive)
        return $res
    }
    return $webApp
}

function Get-IISWebSite(){
    param(
        $ComputerName,
        [Parameter(Mandatory = $true)]$Name
    )
    
    $webSite = Invoke-ScriptBlock -ComputerName $ComputerName -Arguments $Name -scriptBlock {
        param($name)
        #Import-Module WebAdministration
        $res = Get-Website -Name $name | select id, name, physicalPath, enabledProtocols, applicationPool, state
        $res.physicalPath = $res.physicalPath.Replace("%SystemDrive%", $env:SystemDrive)
       
        return $res
    }
    return $webSite
}

function Get-IISWebItem(){
    param(
        $ComputerName,
        [Parameter(Mandatory = $true)]$Name
    )
    
    $res = Invoke-ScriptBlock -ComputerName $ComputerName -Arguments $Name -scriptBlock {
        param($name)
        Import-Module WebAdministration
        $name = "IIS:sites/" + $name
        $res = Get-Item $name | select id, name, physicalPath, enabledProtocols, applicationPool, state
        $res.physicalPath = $res.physicalPath.Replace("%SystemDrive%", $env:SystemDrive)
       
        return $res
    }
    return $res
}



