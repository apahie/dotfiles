function run-bash
    if test (count $argv) -gt 0
        bash -c "$argv"
    else
        powershell.exe -command Get-Clipboard | tr -d '\r' | bash
    end
end

