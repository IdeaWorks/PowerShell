Param(
    $ConnectionName = ,
    $TestConnectionIP = ,
    $action = 'PrintFunctions'
)
$fortiClientTool = join-path ${env:ProgramFiles(x86)} 'Fortinet\FortiClient\FortiSSLVPNclient.exe'

function Connect-FortiClientVpn(){
    param (
        [Parameter(Mandatory = $true)] $ConnectionName,
        [Parameter(Mandatory = $true)] $TestConnectionIP
    )
    Process {
        Write-Host 'Connecting to FortiClientVPN' $ConnectionName 
        & $fortiClientTool connect -s $ConnectionName -i
        Start-Sleep -Seconds 3

        for ($i=0; $i -le 10; $i++){
            try {
                Write-Host Waiting for the VPN to be connected...Testing IP [$TestConnectionIP] attempt $i
                #$result = Test-Connection -ComputerName $TestPingIP -Source localhost -Count 3 -Delay 2 -TTL 255 -BufferSize 256 -ThrottleLimit 32 #-ErrorAction SilentlyContinue
                $result = Test-WSMan $TestConnectionIP -ErrorAction SilentlyContinue
                #Write-Host $result
                if ($result -ne $null){
                    Write-Host 'VPN connection has been established.'
                    break;
                }
                #Write-Host $result
            } catch {
                Write-Host 'Cannot connect to'# $machine
                #break
                throw
            }
        }
    }
}

function Disconnect-FortiClientVpn(){
    param(
        [Parameter(Mandatory = $true)] $ConnectionName
    )
    Process {
        & $fortiClientTool disconnect -s $ConnectionName

        Write-Host 'Disconnecting From FortiClientVPN' $ConnectionName '...'
        Start-Sleep -Seconds 5
    }

}

function Connect (){
    Connect-FortiClientVpn -ConnectionName $ConnectionName -TestConnectionIP $TestConnectionIP
}

function Disconnect (){
    Disconnect-FortiClientVpn -ConnectionName $ConnectionName
}

try{
    
    $contextCmds = Get-Command
    Invoke-FunctionByName $action $contextCmds
    
    if ($script:error.count -gt 0){
        throw
    }

} catch {
    Write-Host $_ | select *
    exit 1

}