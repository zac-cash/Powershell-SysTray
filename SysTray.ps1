#Location of Bin folder on IDrive
$BinLocation = "\\grcorp.guaranteedrate.ad\gri\Information Technology\Software\TechSquad Systray tool\Systray"

if (!(Test-Path .\config.json)){
    try{
        Import-Module ExchangeOnlineManagement -ErrorAction Stop
    } catch {
    Write-host "You need to install the Exchange Online Module for this."
    write-host "Please open a Administrator Powershell window and enter the command: Install-Module ExchangeOnlineManagement "
    
    pause
    exit
    }
    Copy-Item ".\bin\sample.json" -Destination ".\config.json"

    $GRA = Read-host "What is your GRA username? Only enter your username."
    $proper = Read-host "What is your Properrate username? Only enter your username"

    $configuration = Get-Content .\bin\sample.json |ConvertFrom-Json
    $configuration.'Active Directory'[1].Arguements = $configuration.'Active Directory'[1].Arguements.Replace("username",$GRA)
    $configuration.'Active Directory'[2].Arguements = $configuration.'Active Directory'[2].Arguements.Replace("username",$Proper)

    $configuration | ConvertTo-Json | Set-Content .\config.json

}
#Load necessary assembilies
Add-Type -AssemblyName 'System.Windows.Forms'

Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
 
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

#functions needed
function Start-ShowConsole {
    $PSConsole = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($PSConsole, 5)
}
 
function Start-HideConsole {
    $PSConsole = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($PSConsole, 0)
}

function New-MenuItem{
    param(
        [string]$Name,
        [String]$Type,
        [string]$Location,
        [string]$Snippet,
        [string]$arguements,
        
        [switch]
        $ExitOnly = $false,
        [switch]
        $UpdateOnly = $false,
        [switch]
        $easterEgg = $false
    )

    #Initialization
    $MenuItem = New-Object System.Windows.Forms.MenuItem

    #Apply desired text
    if($Name){
        $MenuItem.Text = $Name
    }

    #Apply click event logic for scripts
    if($Type -eq "script" -and !$ExitOnly){
        $MenuItem | Add-Member -Name Location -Value $Location -MemberType NoteProperty
        $MenuItem.Add_Click({
            try{
                $Location = $This.Location #Used to find proper path during click event
                if(Test-Path $Location){
                    Start-Process -FilePath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-NoProfile -NoLogo -ExecutionPolicy Bypass -File `"$Location`"" -ErrorAction Stop
                } else {
                    throw "Could not find at path: $Location"
                }

            } catch {
                $Name = $This.Text
                [System.Windows.Forms.MessageBox]::Show("Failed to launch $Name`n`n$_") > $null
            }
        })
    }

    #Apply click event logic for Code Snippets
    if($Type -eq "Snippet" -and !$ExitOnly){
        $MenuItem | Add-Member -Name Snippet -Value $Snippet -MemberType NoteProperty
        $MenuItem.Add_Click({
                $Snippet = $this.snippet
                $Encoded = [convert]::ToBase64String([System.Text.encoding]::Unicode.GetBytes($Snippet)) 
                Start-Process -FilePath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-NoProfile -NoLogo -Noexit -ExecutionPolicy Bypass -Encoded $Encoded" -ErrorAction Stop
        })
    }
    #Apply click event logic for Applications
    if($Type -eq "Application" -and !$ExitOnly){
        $MenuItem | Add-Member -Name Location -Value $Location -MemberType NoteProperty
        $MenuItem | Add-Member -Name Arguements -Value $Arguements -MemberType NoteProperty
        $MenuItem.Add_Click({
            try{
                $Location = $This.Location #Used to find proper path during click event
                $Arguements = $This.arguements
                
                #test if location supplied is valid
                if(Test-Path $Location){
                    
                    #test if arguments are needed
                    if ($Arguements -eq ""){
                        Start-Process -FilePath $Location -ErrorAction Stop
                    }
                    else {
                        Start-Process -FilePath $Location -ArgumentList $arguements -ErrorAction Stop
                    }

                } else {
                    throw "Could not find at path: $Location"
                }
            } catch {
                $Name = $This.Text
                [System.Windows.Forms.MessageBox]::Show("Failed to launch $Name`n`n$_") > $null
            }
        })
    }

    #Apply click event logic for CopyToClipboard
    if($Type -eq "CopyToClipboard" -and !$ExitOnly){
        $MenuItem | Add-Member -Name Location -Value $Location -MemberType NoteProperty
        $MenuItem.Add_Click({
            try{
                $Location = $This.Location #Used to find proper path during click event
                
                if(Test-Path $Location){
                    
                  Get-Content -Path $Location | Set-Clipboard

                } else {
                    throw "Could not find at path: $Location"
                }
            } catch {
                $Name = $This.Text
                [System.Windows.Forms.MessageBox]::Show("Failed to add to clipboard: $Name`n`n$_") > $null
            }

       })
    }
    #Provide a way to exit the launcher
    if($UpdateOnly -and !$MyScriptPath){
        $MenuItem | Add-Member -Name Location -Value $Location -MemberType NoteProperty
        $MenuItem.Add_Click({
        try{
                $ScriptPath = ".\SysTray.ps1"
                $Location = $This.Location #Used to find proper path during click event
                
                if(Test-Path $Location){
                    Copy-Item -path $Location -Destination $env:OneDriveCommercial\ -Force -Recurse
                } else {
                    throw "Could not find at path: $Location"
                }
                
                [System.Windows.Forms.MessageBox]::Show("Updating. Please wait 5 seconds then press okay.") > $null

                Remove-Item .\config.json -Force
                Start-Process -FilePath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-NoProfile -Noexit -nologo -ExecutionPolicy Bypass -file $ScriptPath" -ErrorAction Stop
                
                $Form.close()
                Stop-Process $PID
            } catch {
                $Name = $This.Text
                [System.Windows.Forms.MessageBox]::Show("Error: $Name`n`n$_") > $null
            }
            
        })
    }

    if($EasterEgg -and !$MyScriptPath){
        $MenuItem.Add_Click({
            $PlayWav=New-Object System.Media.SoundPlayer
            $PlayWav.SoundLocation = "$((get-location).Path)\bin\For Leon.wav"
            $playwav.PlaySync()
        })
    }

    if($ExitOnly -and !$MyScriptPath){
        $MenuItem.Add_Click({
            $Form.Close()

            #Handle any hung processes
            Stop-Process $PID
        })
    }
    #Return our new MenuItem
    $MenuItem
}

#Create Form to serve as a container for our components
$Form = New-Object System.Windows.Forms.Form

#Configure our form to be hidden
$Form.BackColor = "Magenta" #Pick a color you won't use again and match it to the TransparencyKey property
$Form.TransparencyKey = "Magenta"
$Form.ShowInTaskbar = $false
$Form.FormBorderStyle = "None"

#Initialize/configure necessary components
$SystrayLauncher = New-Object System.Windows.Forms.NotifyIcon
$SystrayIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe")
$SystrayLauncher.Icon = $SystrayIcon
$SystrayLauncher.Text = "PowerShell Launcher"
$SystrayLauncher.Visible = $true

$ContextMenu = New-Object System.Windows.Forms.ContextMenu

$EasterEgg = New-MenuItem -Name "~ PowerShell Launcher ~" -EasterEgg
$ContextMenu.MenuItems.AddRange($EasterEgg)

#Load configuration file
$configuration = Get-Content .\config.json |ConvertFrom-Json
$menus = $configuration |Get-Member -MemberType NoteProperty |Select-Object -Property name -ExpandProperty name

#This section Loops through each submenu to add the menu items.
#-Each element of the submenu array is generated into a Menu Item object via the New-MenuItem function.
#-Those menuitems objects ($addsubject) are fed into $temp
#-Temp is then added as a submenu for the context menu
Foreach ($submenu in $menus){
    $temp = New-Object System.Windows.Forms.MenuItem
    $temp.text = $submenu

    foreach ($Script in $configuration.($submenu)) {
        $addScript = New-MenuItem -name $script.Name -Type $Script.type -Location $Script.location -Snippet $Script.snippet -arguements $Script.arguements
        $temp.MenuItems.Add($addScript)
    }
    $ContextMenu.MenuItems.AddRange($Temp)
}

$UpdateBin = New-MenuItem -Name "Update Systray" -UpdateOnly -Location $BinLocation
$ContextMenu.MenuItems.AddRange($UpdateBin)

#Add a exit option to the main menu
$ExitLauncher = New-MenuItem -Name "Exit" -ExitOnly
$ContextMenu.MenuItems.AddRange($ExitLauncher)

#Add components to our form
$SystrayLauncher.ContextMenu = $ContextMenu

#Launch
Start-HideConsole
$Form.ShowDialog() > $null
Start-ShowConsole