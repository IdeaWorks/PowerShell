

function Get-IISWebSite($ComputerName, $WebSiteName){
    Import-Module PsUtil.Remoting
    $siteObj = Invoke-ScriptBlock -ComputerName $ComputerName -Arguments $WebSiteName -scriptBlock {
        param ($siteName)
        Import-Module WebAdministration
        $siteName = 'IIS:\sites\' + $siteName
        $siteObj = Get-Item $siteName | select *
        #Write-Host $siteObj
        return $siteObj
        
    }
    return $siteObj

}

function Get-IISWebSitePhysicalPath(){
    param(
        $ComputerName,
        $WebSiteName
    )
    Process{
        $site = Get-IISWebSite -ComputerName $computerName -WebSiteName $WebSiteName
        $physicalPath = $site.PhysicalPath.Replace("%SystemDrive%", $env:SystemDrive)
        return $physicalPath
    }
}