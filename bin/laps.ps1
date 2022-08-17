function Test-ADCredential {
  param(
    [System.Management.Automation.Credential()]
    $Credential
  )

    Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
    $info = $Credential.GetNetworkCredential()

    $TypeDomain = [System.DirectoryServices.AccountManagement.ContextType]::Domain
        $pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext $TypeDomain,$info.Domain
        $pc.ValidateCredentials($info.UserName,$info.Password,[DirectoryServices.AccountManagement.ContextOptions]::Negotiate -bor [DirectoryServices.AccountManagement.ContextOptions]::Sealing)
    
}


Write-host "Hello!"
Write-host "Please enter your AD credentials when prompted. (ex: Domain\username)"
Write-host "You will need to be on VPN"
$goodcred = $False
    While (!$goodcred){
        $cred = (Get-Credential -username Domain\$env:username -message 'Please doublecheck your username')
    
        If (Test-ADCredential $cred){
            $goodcred = $True
        } else {
            $attempt +=1
            If ($attempt -eq 3){exit}
            Write-host "unable to authenticate creds. Please try again."
            pause
        }
    }

cls
$loop = $true
While ($true){

    $computer = Read-Host "Please enter the computername that you need the Admin Password for"
    try{
        $Properties= Get-ADComputer -Credential $cred -Identity $computer -Properties 'ms-Mcs-AdmPwd' -Server "Domain" -ErrorAction Stop
    } catch {
        Write-host "Script could not grab admin password. Please attempt manually to see if computer is in AD." -BackgroundColor Red
    }
    $password = $Properties.'ms-Mcs-AdmPwd'
    Set-Clipboard $password
    Write-host "`n"
    Write-host "The Admin Password for $computer is $password and has also been copied to your clipboard."
    Write-host "`n"
    pause
    cls
}

