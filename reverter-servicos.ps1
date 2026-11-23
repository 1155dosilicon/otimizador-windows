# =================================================================
# Reverte as otimizacoes #18 (servicos) e #19 (svchost) do otimizador.ps1
# usando o backup salvo em %ProgramData%\OtimizadorWindows. Executar como Administrador.
# =================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Por favor, execute este script como Administrador."
    exit
}

$backupDir  = Join-Path $env:ProgramData "OtimizadorWindows"
$backupFile = Join-Path $backupDir "backup-servicos.csv"
if (!(Test-Path $backupFile)) {
    Write-Error "Backup nao encontrado em $backupFile"
    exit 1
}

$negados = @()
foreach ($l in Import-Csv $backupFile) {
    if ($l.Name -eq "__SvcHostSplitThresholdInKB") {
        if ($l.Start) {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Value ([int]$l.Start) -Type DWord
        } else {
            Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -ErrorAction SilentlyContinue
        }
        Write-Host "[ok] svchost restaurado" -ForegroundColor Green
        continue
    }
    $chave = "HKLM:\SYSTEM\CurrentControlSet\Services\$($l.Name)"
    if (!(Test-Path $chave)) { continue }
    Set-ItemProperty -Path $chave -Name "Start" -Value ([int]$l.Start) -Type DWord -ErrorAction SilentlyContinue
    if ((Get-ItemProperty $chave).Start -eq [int]$l.Start) {
        Write-Host "[ok] $($l.Name)" -ForegroundColor Green
    } else {
        $negados += $l
    }
}

# Chaves que so a conta SISTEMA pode alterar
if ($negados.Count -gt 0) {
    $logSistema = Join-Path $backupDir "log-sistema.txt"
    Remove-Item $logSistema -ErrorAction SilentlyContinue
    $cmds = foreach ($l in $negados) {
        "Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\$($l.Name)' -Name Start -Value $([int]$l.Start)"
    }
    $cmds += "'FIM' | Out-File '$logSistema'"
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes(($cmds -join "`n")))
    $acao = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -EncodedCommand $enc"
    Register-ScheduledTask -TaskName "OtimizadorTemp" -Action $acao -User "SYSTEM" -RunLevel Highest -Force | Out-Null
    Start-ScheduledTask -TaskName "OtimizadorTemp"
    $espera = 0
    while (!(Test-Path $logSistema) -and $espera -lt 60) { Start-Sleep -Milliseconds 500; $espera++ }
    Unregister-ScheduledTask -TaskName "OtimizadorTemp" -Confirm:$false -ErrorAction SilentlyContinue
    foreach ($l in $negados) {
        if ((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$($l.Name)").Start -eq [int]$l.Start) {
            Write-Host "[ok] $($l.Name) (via SISTEMA)" -ForegroundColor Green
        } else {
            Write-Warning "Nao foi possivel restaurar $($l.Name)"
        }
    }
}

Write-Host "`nRestaurado. Reinicie o computador." -ForegroundColor Cyan
