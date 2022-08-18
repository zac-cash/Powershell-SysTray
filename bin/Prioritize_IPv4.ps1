ping $env:computername

New-ItemProperty "HKLM:\system\CurrentControlSet\Services\Tcpip\Parameters\" -name "DisabledComponents" -Value 0x20 -PropertyType "Dword"
Set-ItemProperty "HKLM:\system\CurrentControlSet\Services\Tcpip\Parameters\" -name "DisabledComponents" -Value 0x20