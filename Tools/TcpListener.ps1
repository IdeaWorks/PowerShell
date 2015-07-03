param (
    $Port
)

function Listen-Port {
    param (
        [Parameter(Mandatory = $true)] $Port
    )
    {
        $endpoint = new-object System.Net.IPEndPoint ([system.net.ipaddress]::any, $Port)
        $listener = new-object System.Net.Sockets.TcpListener $endpoint
        $listener.start()
        do {
            write-host Listening on port $Port ...
            $client = $listener.AcceptTcpClient() 
            $stream = $client.GetStream();
            $reader = New-Object System.IO.StreamReader $stream
            do {

                $line = $reader.ReadLine()
                write-host $line -fore cyan
            } while ($line -and $line -ne ':q')
            $reader.Dispose()
            $stream.Dispose()
            $client.Dispose()
        } while ($line -ne ':q')
        $listener.stop()
    }
}


Listen-Port -port $Port
