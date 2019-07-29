Function Install-Graylog {
    <#  
    .SYNOPSIS  
        Install Graylog Sidecar 1.0.1.1 to a Windows node
    .DESCRIPTION  
        Installs Graylog and sets default settings for windows 
        logging to allow configuration management via Graylog Configuration Manager
    .NOTES  
        File Name   : Install-Graylog.ps1  
        Author      : Justin Leopold - 7/31/2019
        Written on  : Powershell 5.1
    .LINK  
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Enter Computer Name(s)")]   
        [Alias('hostname', 'cn', 'name')]
        [string[]]$ComputerName,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Cred = [System.Management.Automation.PSCredential]::Empty
    )

    BEGIN {
        
    }

    PROCESS {
        Foreach ($computer in $ComputerName) {

            New-PSDrive -Name "R" -PSProvider "FileSystem" -Root "\\$computer\c$\windows\Temp" -Credential $cred
            Copy-Item -Path "Path\graylog_sidecar_installer_1.0.1-1.exe" -Destination R:\
            Invoke-Command -ComputerName $computer -ScriptBlock { Start-Process  "c:\windows\temp\graylog_sidecar_installer_1.0.1-1.exe" -ArgumentList "/S", "-SERVERURL=http://servername/api", "-APITOKEN=token" -Wait } -Credential $cred
            New-PSDrive -Name "I" -PSProvider "FileSystem" -Root "\\$computer\c$\Program Files\Graylog\sidecar" -Credential $cred
            #Below is a workaround due to the default YML file not having a blank hostname. this may be fixed in a new sidecar release.
            Copy-Item -Path "Path\graylog_sidecar_installer_1.0.1-1.exe\Graylog\sidecar.yml" -Destination I:\
            Invoke-Command -ComputerName $computer -ScriptBlock { Start-Process 'C:\Program Files\graylog\sidecar\graylog-sidecar.exe' -ArgumentList "-service", "install" -Wait } -Credential $cred
            Invoke-Command -ComputerName $computer -ScriptBlock { Start-Process 'C:\Program Files\graylog\sidecar\graylog-sidecar.exe' -ArgumentList "-service", "start" -Wait } -Credential $cred
            Remove-PSDrive I
            Remove-PSDrive R

        }#foreach
    }#process

}#function


Function Remove-Graylog {
    <#  
    .SYNOPSIS  
        Remove Graylog Collector Sidecar from a Windows node
    .DESCRIPTION  
        Remove Graylog Collector Sidecar from a Windows node
    .NOTES  
        File Name   : Remove-Graylog.ps1  
        Author      : Justin Leopold - 7/31/2019
        Written on  : Windows Powershell 5.1
    .LINK  
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Enter Computer Name(s)")]   
        [Alias('hostname', 'cn', 'name')]
        [string[]]$ComputerName,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Cred = [System.Management.Automation.PSCredential]::Empty
    )

    BEGIN {
        
    }

    PROCESS {
        Foreach ($computer in $ComputerName) {
            Invoke-Command -ComputerName $computer -ScriptBlock { Start-Process 'C:\Program Files\graylog\sidecar\graylog-sidecar.exe' -ArgumentList "-service", "stop" -Wait } -Credential $cred
            Invoke-Command -ComputerName $computer -ScriptBlock { Start-Process 'C:\Program Files\graylog\sidecar\graylog-sidecar.exe' -ArgumentList "-service", "uninstall" -Wait } -Credential $cred
        }#foreach
    }#process

}#function

Function Get-Graylog {
    <#  
    .SYNOPSIS  
        Check a server(s) to see if the Graylog collector sidecar is installed.
    .DESCRIPTION  
        Remove Graylog Collector Sidecar from a Windows node
    .NOTES  
        File Name   : Get-Graylog.ps1  
        Author      : Justin Leopold - 7/31/2019
        Written on  : Windows Powershell 5.1
    .LINK  
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Enter Computer Name(s)")]   
        [Alias('hostname', 'cn', 'name')]
        [string[]]$ComputerName,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Cred = [System.Management.Automation.PSCredential]::Empty
    )

    BEGIN {
        Write-Verbose -Message "Checking for the Graylog Sidecar" 
    }

    PROCESS {
        Foreach ($computer in $ComputerName) {
            $Software = "Graylog Sidecar";
            TRY {
                $Installed = ($null -ne (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
                Where-Object { $_.DisplayName -eq "$Software" }))
            }
            CATCH {
                Write-Output $_
            }
            $Message = "Is Graylog Installed " + $Installed
            Write-Output $Message
        }#foreach
    }#process

}#function