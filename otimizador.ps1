# =================================================================
# SCRIPT DE OTIMIZACAO POS-INSTALACAO (WINDOWS 10/11)
# Compativel com Windows 11 21H2+
# =================================================================

# Verifica se esta rodando como Administrador
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Por favor, execute este script como Administrador."
    exit
}

Write-Host "--- Iniciando Otimizacoes ---" -ForegroundColor Cyan

# 1. DESATIVAR MITIGACOES DO PROCESSADOR (Spectre/Meltdown)
Write-Host "[>] Desativando mitigacoes do processador (Performance Boost)..." -ForegroundColor Yellow
$memMgmt = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
try {
    Set-ItemProperty -Path $memMgmt -Name "FeatureSettingsOverride" -Value 3 -Type DWord -ErrorAction Stop
    Set-ItemProperty -Path $memMgmt -Name "FeatureSettingsOverrideMask" -Value 3 -Type DWord -ErrorAction Stop
    Write-Host "    Mitigacoes desativadas." -ForegroundColor Green
} catch {
    Write-Warning "    Erro ao desativar mitigacoes: $($_.Exception.Message)"
}

# 2. SYSMAIN (SUPERFETCH) CONFORME O DISCO
# HDD: o SysMain acelera bastante (pre-carrega apps) -> mantido.
# SSD: o ganho e minimo, mas o SysMain tambem gerencia a COMPRESSAO DE MEMORIA,
#      que e importante com pouca RAM -> so desativa com SSD e RAM >= $ramMinimaGB.
Write-Host "[>] Verificando SysMain (Superfetch)..." -ForegroundColor Yellow
$ramMinimaGB = 16
try {
    $discoSistema = (Get-Partition -DriveLetter $env:SystemDrive[0] -ErrorAction Stop).DiskNumber
    $fisico = Get-PhysicalDisk -ErrorAction Stop | Where-Object { $_.DeviceId -eq "$discoSistema" } | Select-Object -First 1
    $ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    $ehSSD = $fisico -and ($fisico.MediaType -eq 'SSD' -or $fisico.BusType -eq 'NVMe')
    $ehHDD = $fisico -and $fisico.MediaType -eq 'HDD'

    if ($ehSSD -and $ramGB -ge $ramMinimaGB) {
        Stop-Service -Name SysMain -Force -ErrorAction SilentlyContinue
        Set-Service -Name SysMain -StartupType Disabled -ErrorAction Stop
        Write-Host "    SSD + $ramGB GB de RAM: SysMain desativado." -ForegroundColor Green
    } elseif ($ehSSD) {
        Write-Host "    SSD, mas so $ramGB GB de RAM: SysMain mantido (compressao de memoria)." -ForegroundColor Green
    } elseif ($ehHDD) {
        Write-Host "    HDD detectado: SysMain mantido (acelera o disco)." -ForegroundColor Green
    } else {
        Write-Host "    Tipo de disco nao identificado: SysMain mantido por seguranca." -ForegroundColor Yellow
    }
} catch {
    Write-Warning "    Erro ao verificar o disco/SysMain: $($_.Exception.Message)"
}

# 3. DESATIVAR TELEMETRIA E COLETA DE DADOS
Write-Host "[>] Desativando telemetria e servicos de rastreio..." -ForegroundColor Yellow
$telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (!(Test-Path $telemetryPath)) { New-Item -Path $telemetryPath -Force | Out-Null }
try {
    Set-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction Stop
} catch {
    Write-Warning "    Erro ao configurar telemetria: $($_.Exception.Message)"
}
Stop-Service -Name DiagTrack -Force -ErrorAction SilentlyContinue | Out-Null
Set-Service -Name DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name dmwappushservice -Force -ErrorAction SilentlyContinue | Out-Null
Set-Service -Name dmwappushservice -StartupType Disabled -ErrorAction SilentlyContinue
Write-Host "    Telemetria e servicos de rastreio desativados." -ForegroundColor Green

# 4. DESATIVAR BING NA PESQUISA DO MENU INICIAR
Write-Host "[>] Removendo Bing da pesquisa local..." -ForegroundColor Yellow
$searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
$explorerPolicyPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
$searchPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"

if (!(Test-Path $searchPath)) { New-Item -Path $searchPath -Force | Out-Null }
if (!(Test-Path $explorerPolicyPath)) { New-Item -Path $explorerPolicyPath -Force | Out-Null }
if (!(Test-Path $searchPolicyPath)) { New-Item -Path $searchPolicyPath -Force | Out-Null }

try {
    Set-ItemProperty -Path $searchPath -Name "BingSearchEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $searchPath -Name "CortanaConsent" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $explorerPolicyPath -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -ErrorAction Stop
    Set-ItemProperty -Path $searchPolicyPath -Name "DisableCloudSearch" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $searchPolicyPath -Name "AllowCortana" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "    Bing removido da pesquisa local." -ForegroundColor Green
} catch {
    Write-Warning "    Erro ao desativar Bing: $($_.Exception.Message)"
}

# 5. DESATIVAR AVISO MS-GAMINGOVERLAY (WIN+G)
Write-Host "[>] Desativando avisos de Game Overlay..." -ForegroundColor Yellow
$gameDvr = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
$gameConfig = "HKCU:\System\GameConfigStore"
$gamePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"

if (!(Test-Path $gameDvr)) { New-Item -Path $gameDvr -Force | Out-Null }
if (!(Test-Path $gameConfig)) { New-Item -Path $gameConfig -Force | Out-Null }
if (!(Test-Path $gamePolicy)) { New-Item -Path $gamePolicy -Force | Out-Null }

try {
    Set-ItemProperty -Path $gameDvr -Name "AppCaptureEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gameConfig -Name "GameDVR_Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gameConfig -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gamePolicy -Name "AllowGameDVR" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "    Avisos de Game Overlay desativados." -ForegroundColor Green
} catch {
    Write-Warning "    Erro no GameDVR: $($_.Exception.Message)"
}

# 6. DESATIVAR SERVICOS XBOX
Write-Host "[>] Desativando servicos Xbox..." -ForegroundColor Yellow
$servicosXbox = @("XblAuthManager","XblGameSave","XboxNetApiSvc","XboxGipSvc")
foreach ($svc in $servicosXbox) {
    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
}
Write-Host "    Servicos Xbox desativados." -ForegroundColor Green

# 7. DESATIVAR DICAS E SUGESTOES DO WINDOWS
Write-Host "[>] Desativando dicas e sugestoes..." -ForegroundColor Yellow
$tipsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (!(Test-Path $tipsPath)) { New-Item -Path $tipsPath -Force | Out-Null }
try {
    Set-ItemProperty -Path $tipsPath -Name "SoftLandingEnabled" -Value 0 -Type DWord -ErrorAction Stop
    Set-ItemProperty -Path $tipsPath -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $tipsPath -Name "SubscribedContent-338393Enabled" -Value 0 -Type DWord -ErrorAction Stop
    Set-ItemProperty -Path $tipsPath -Name "SubscribedContent-353694Enabled" -Value 0 -Type DWord -ErrorAction Stop
    Set-ItemProperty -Path $tipsPath -Name "SubscribedContent-353696Enabled" -Value 0 -Type DWord -ErrorAction Stop
    Set-ItemProperty -Path $tipsPath -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "    Dicas e sugestoes desativadas." -ForegroundColor Green
} catch {
    Write-Warning "    Erro ao desativar dicas: $($_.Exception.Message)"
}

# 8. DESATIVAR HIBERNACAO (Libera GBs de espaco)
Write-Host "[>] Desativando hibernacao..." -ForegroundColor Yellow
$hibernar = Start-Process -FilePath "powercfg" -ArgumentList "-h off" -Wait -NoNewWindow -PassThru
if ($hibernar.ExitCode -eq 0) {
    Write-Host "    Hibernacao desativada (arquivo hiberfil.sys removido)." -ForegroundColor Green
} else {
    Write-Warning "    Erro ao desativar hibernacao (codigo $($hibernar.ExitCode))."
}

# 9. DESATIVAR OTIMIZACAO DE ENTREGA (P2P de updates)
Write-Host "[>] Desativando Otimizacao de Entrega (P2P)..." -ForegroundColor Yellow
$deliveryOptPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
if (!(Test-Path $deliveryOptPath)) { New-Item -Path $deliveryOptPath -Force | Out-Null }
try {
    Set-ItemProperty -Path $deliveryOptPath -Name "DODownloadMode" -Value 0 -Type DWord -ErrorAction Stop
    Write-Host "    Otimizacao de entrega (P2P) desativada." -ForegroundColor Green
} catch {
    Write-Warning "    Erro no Delivery Optimization: $($_.Exception.Message)"
}

# 10. DESATIVAR APPS EM SEGUNDO PLANO
Write-Host "[>] Desativando apps em segundo plano..." -ForegroundColor Yellow
$bgAppsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
if (!(Test-Path $bgAppsPath)) { New-Item -Path $bgAppsPath -Force | Out-Null }
try {
    Set-ItemProperty -Path $bgAppsPath -Name "GlobalUserDisabled" -Value 1 -Type DWord -ErrorAction Stop
    Write-Host "    Apps em segundo plano limitados." -ForegroundColor Green
} catch {
    Write-Warning "    Erro nos apps em segundo plano: $($_.Exception.Message)"
}

# 11. PLANO DE ENERGIA - DESEMPENHO MAXIMO (Ultimate Performance)
Write-Host "[>] Ativando plano Desempenho Maximo..." -ForegroundColor Yellow
$guidMaximo = "e9a42b02-d5df-448d-aa00-03f14749eb61"
$guidAlto   = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
$regexGuid  = '([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})'
$planoAtivado = $null

# 1) Ja existe um plano Desempenho Maximo (original ou copia de execucao anterior)? Usa ele.
$linha = powercfg -list 2>&1 | Where-Object { $_ -match "Desempenho M.ximo|Ultimate Performance" } | Select-Object -First 1
if ($linha -and "$linha" -match $regexGuid) {
    powercfg -setactive $Matches[1] 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $planoAtivado = "Desempenho Maximo" }
}
# 2) Plano oculto (padrao na maioria dos PCs): cria a partir do modelo e ativa a copia
if (-not $planoAtivado) {
    $saida = powercfg -duplicatescheme $guidMaximo 2>&1
    if ($LASTEXITCODE -eq 0 -and "$saida" -match $regexGuid) {
        powercfg -setactive $Matches[1] 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $planoAtivado = "Desempenho Maximo" }
    }
}
# 3) Fallback: Alto Desempenho (alguns notebooks com Modern Standby bloqueiam o Maximo)
if (-not $planoAtivado) {
    powercfg -setactive $guidAlto 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        $saida = powercfg -duplicatescheme $guidAlto 2>&1
        if ("$saida" -match $regexGuid) { powercfg -setactive $Matches[1] 2>&1 | Out-Null }
    }
    if ($LASTEXITCODE -eq 0) { $planoAtivado = "Alto Desempenho (Desempenho Maximo indisponivel neste PC)" }
}

if ($planoAtivado) {
    Write-Host "    Plano $planoAtivado ativado." -ForegroundColor Green
} else {
    Write-Warning "    Nao foi possivel ativar o plano Desempenho Maximo."
}

# 12. DESATIVAR WIDGETS (Windows 11)
Write-Host "[>] Desativando Widgets..." -ForegroundColor Yellow
$widgetsPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (!(Test-Path $widgetsPath)) { New-Item -Path $widgetsPath -Force | Out-Null }
try {
    Set-ItemProperty -Path $widgetsPath -Name "AllowNewsAndInterests" -Value 0 -Type DWord -ErrorAction Stop
    Write-Host "    Widgets desativados." -ForegroundColor Green
} catch {
    Write-Warning "    Erro ao desativar Widgets: $($_.Exception.Message)"
}

# 13. LIMPEZA DE ARQUIVOS TEMPORARIOS
Write-Host "[>] Limpando arquivos temporarios..." -ForegroundColor Yellow
$tempErros = 0
@($env:TEMP, "C:\Windows\Temp") | ForEach-Object {
    if (Test-Path -LiteralPath $_) {
        Get-ChildItem -Path $_ -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            if (Test-Path -LiteralPath $_.FullName) {
                try {
                    Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
                } catch {
                    # Arquivos em uso serao ignorados silenciosamente
                    $tempErros++
                }
            }
        }
    }
}
if ($tempErros -gt 0) {
    Write-Host "    Limpeza concluida ($tempErros itens em uso foram ignorados)." -ForegroundColor Yellow
} else {
    Write-Host "    Arquivos temporarios removidos." -ForegroundColor Green
}

# 14. DESATIVAR MENU DE CONTEXTO NOVO DO WINDOWS 11 (Restaurar classico)
Write-Host "[>] Desativando menu de contexto moderno (restaurando classico)..." -ForegroundColor Yellow
$ctxMenuPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
if (!(Test-Path $ctxMenuPath)) { New-Item -Path $ctxMenuPath -Force | Out-Null }
$inprocPath = "$ctxMenuPath\InprocServer32"
if (!(Test-Path $inprocPath)) { New-Item -Path $inprocPath -Force | Out-Null }
try {
    Set-ItemProperty -Path $inprocPath -Name "(default)" -Value "" -Type String -ErrorAction Stop
    Write-Host "    Menu de contexto classico restaurado." -ForegroundColor Green
} catch {
    Write-Warning "    Erro ao restaurar menu classico: $($_.Exception.Message)"
}

# 15. REMOVER ACESSO RAPIDO DO WINDOWS EXPLORER
Write-Host "[>] Removendo Acesso Rapido do Explorer..." -ForegroundColor Yellow
$explorerAdv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (!(Test-Path $explorerAdv)) { New-Item -Path $explorerAdv -Force | Out-Null }
$explorerBase = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
$quickAccessOk = $true
try {
    Set-ItemProperty -Path $explorerAdv -Name "HubMode" -Value 1 -Type DWord -ErrorAction Stop
    Set-ItemProperty -Path $explorerAdv -Name "LaunchTo" -Value 1 -Type DWord -ErrorAction Stop
} catch {
    Write-Warning "    Erro ao configurar Explorer Advanced: $($_.Exception.Message)"
    $quickAccessOk = $false
}
# Desativa arquivos recentes e pastas frequentes
try {
    Set-ItemProperty -Path $explorerBase -Name "ShowRecent" -Value 0 -Type DWord -ErrorAction Stop
    Set-ItemProperty -Path $explorerBase -Name "ShowFrequent" -Value 0 -Type DWord -ErrorAction Stop
} catch {
    Write-Warning "    Erro ao desativar recentes/frequentes: $($_.Exception.Message)"
    $quickAccessOk = $false
}
if ($quickAccessOk) {
    Write-Host "    Acesso Rapido removido e Explorer abre em 'Este Computador'." -ForegroundColor Green
}

# 16. DESATIVAR CrossDeviceResume (Windows 11 - cross-device/resume)
Write-Host "[>] Desativando CrossDeviceResume..." -ForegroundColor Yellow
$taskName = "\Microsoft\Windows\Shell\Kill CrossDeviceResume.exe"
try {
    $result = schtasks /create /sc OnLogon /delay 0000:03 /tn $taskName /tr "taskkill /im CrossDeviceResume.exe /f" /ru SYSTEM /f 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    CrossDeviceResume desativado (tarefa agendada criada)." -ForegroundColor Green
    } else {
        Write-Warning "    Erro ao criar tarefa agendada: $result"
    }
} catch {
    Write-Warning "    Erro ao desativar CrossDeviceResume: $($_.Exception.Message)"
}

# 17. REMOVER HOME E GALERIA DO EXPLORER (Windows 11 24H2)
Write-Host "[>] Removendo 'Home' e 'Galeria' do Explorer..." -ForegroundColor Yellow
$homeClsidPath = "HKCU:\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"
$galleryClsidPath = "HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
$homeGalleryOk = $true

# Desafixar Home
if (!(Test-Path $homeClsidPath)) { New-Item -Path $homeClsidPath -Force | Out-Null }
try {
    Set-ItemProperty -Path $homeClsidPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -ErrorAction Stop
} catch {
    Write-Warning "    Erro ao remover Home: $($_.Exception.Message)"
    $homeGalleryOk = $false
}

# Desafixar Galeria
if (!(Test-Path $galleryClsidPath)) { New-Item -Path $galleryClsidPath -Force | Out-Null }
try {
    Set-ItemProperty -Path $galleryClsidPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -ErrorAction Stop
} catch {
    Write-Warning "    Erro ao remover Galeria: $($_.Exception.Message)"
    $homeGalleryOk = $false
}

if ($homeGalleryOk) {
    Write-Host "    'Home' e 'Galeria' removidos do Explorer." -ForegroundColor Green
}

# 18. DESATIVAR SERVICOS DESNECESSARIOS
Write-Host "[>] Desativando servicos desnecessarios..." -ForegroundColor Yellow
$servicosInuteis = [ordered]@{
    'WSAIFabricSvc'              = 'Componentes de IA do Windows (Copilot/Recall)'
    'InventorySvc'               = 'Avaliacao de inventario/compatibilidade (telemetria)'
    'whesvc'                     = 'Integridade e Experiencias Otimizadas (telemetria)'
    'DPS'                        = 'Politica de Diagnostico (solucionador de problemas)'
    'WdiSystemHost'              = 'Host de diagnosticos'
    'WdiServiceHost'             = 'Host de diagnosticos'
    'TrkWks'                     = 'Rastreamento de links distribuidos (rede corporativa)'
    'SSDPSRV'                    = 'Descoberta UPnP'
    'lmhosts'                    = 'NetBIOS sobre TCP/IP'
    'iphlpsvc'                   = 'Tuneis IPv6 (Teredo/6to4/IP-HTTPS)'
    'AMD Crash Defender Service' = 'Coleta de crash do driver AMD'
}
# Condicionais: so desativa se o PC nao usa o recurso
if (@(Get-PnpDevice -Class Image -PresentOnly -ErrorAction SilentlyContinue).Count -eq 0) {
    $servicosInuteis['StiSvc'] = 'WIA - scanners (nenhum detectado)'
} else {
    Write-Host "    Scanner detectado -- StiSvc mantido." -ForegroundColor DarkGray
}
if (@(Get-SmbShare -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '\$$' }).Count -eq 0) {
    $servicosInuteis['LanmanServer'] = 'Compartilhamento de pastas (nenhuma compartilhada)'
} else {
    Write-Host "    Pastas compartilhadas detectadas -- LanmanServer mantido." -ForegroundColor DarkGray
}

# Backup do estado original (so na primeira execucao, para nunca sobrescrever o original)
$backupDir  = Join-Path $env:ProgramData "OtimizadorWindows"
$backupFile = Join-Path $backupDir "backup-servicos.csv"
if (!(Test-Path $backupFile)) {
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    $linhas = foreach ($nome in $servicosInuteis.Keys) {
        $chave = "HKLM:\SYSTEM\CurrentControlSet\Services\$nome"
        if (Test-Path $chave) { [pscustomobject]@{ Name = $nome; Start = (Get-ItemProperty $chave).Start } }
    }
    $splitAtual = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control").SvcHostSplitThresholdInKB
    $linhas = @($linhas) + [pscustomobject]@{ Name = "__SvcHostSplitThresholdInKB"; Start = $splitAtual }
    $linhas | Export-Csv $backupFile -NoTypeInformation -Encoding UTF8
    Write-Host "    Backup salvo em $backupFile" -ForegroundColor DarkGray
}

$negados = @()
$desativados = 0
foreach ($nome in $servicosInuteis.Keys) {
    $chave = "HKLM:\SYSTEM\CurrentControlSet\Services\$nome"
    if (!(Get-Service -Name $nome -ErrorAction SilentlyContinue)) { continue }
    if ((Get-ItemProperty $chave).Start -eq 4) { $desativados++; continue }
    Stop-Service -Name $nome -Force -ErrorAction SilentlyContinue
    Set-Service -Name $nome -StartupType Disabled -ErrorAction SilentlyContinue
    if ((Get-ItemProperty $chave).Start -ne 4) {
        Set-ItemProperty -Path $chave -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue
    }
    if ((Get-ItemProperty $chave).Start -eq 4) {
        $desativados++
        Write-Host ("    [off] {0} - {1}" -f $nome, $servicosInuteis[$nome]) -ForegroundColor DarkGray
    } else {
        $negados += $nome
    }
}

# Algumas chaves so aceitam escrita da conta SISTEMA: aplica via tarefa temporaria
if ($negados.Count -gt 0) {
    $logSistema = Join-Path $backupDir "log-sistema.txt"
    Remove-Item $logSistema -ErrorAction SilentlyContinue
    $cmds = foreach ($nome in $negados) {
        "sc.exe stop '$nome' | Out-Null; Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\$nome' -Name Start -Value 4"
    }
    $cmds += "'FIM' | Out-File '$logSistema'"
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes(($cmds -join "`n")))
    try {
        $acao = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -EncodedCommand $enc"
        Register-ScheduledTask -TaskName "OtimizadorTemp" -Action $acao -User "SYSTEM" -RunLevel Highest -Force -ErrorAction Stop | Out-Null
        Start-ScheduledTask -TaskName "OtimizadorTemp"
        $espera = 0
        while (!(Test-Path $logSistema) -and $espera -lt 60) { Start-Sleep -Milliseconds 500; $espera++ }
    } catch {
        Write-Warning "    Erro ao criar tarefa como SISTEMA: $($_.Exception.Message)"
    } finally {
        Unregister-ScheduledTask -TaskName "OtimizadorTemp" -Confirm:$false -ErrorAction SilentlyContinue
    }
    foreach ($nome in $negados) {
        if ((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$nome").Start -eq 4) {
            $desativados++
            Write-Host ("    [off] {0} - {1} (via SISTEMA)" -f $nome, $servicosInuteis[$nome]) -ForegroundColor DarkGray
        } else {
            Write-Warning "    Nao foi possivel desativar $nome (acesso negado)."
        }
    }
}
Write-Host "    $desativados servicos desnecessarios desativados." -ForegroundColor Green

# 19. AGRUPAR PROCESSOS SVCHOST
# Com mais de 3,5 GB de RAM o Windows cria um svchost para cada servico.
# Subindo o limite acima da RAM instalada, ele volta a agrupar -> bem menos processos.
Write-Host "[>] Agrupando processos svchost..." -ForegroundColor Yellow
try {
    $ramKB = [math]::Ceiling((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1KB)
    $limite = [int][math]::Min($ramKB + 1048576, [int]::MaxValue)
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Value $limite -Type DWord -ErrorAction Stop
    Write-Host "    svchost agrupado (efeito apos reiniciar)." -ForegroundColor Green
} catch {
    Write-Warning "    Erro ao agrupar svchost: $($_.Exception.Message)"
}

# REINICIAR EXPLORER PARA APLICAR MUDANCAS VISUAIS
Write-Host "---"
Write-Host "[!] O Windows Explorer sera reiniciado para aplicar algumas mudancas." -ForegroundColor Magenta
Write-Host "    Suas janelas abertas piscarao brevemente."
$respExplorer = Read-Host "    Deseja reiniciar o Explorer agora? (S/N)"
if ($respExplorer -eq "S" -or $respExplorer -eq "s") {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Write-Host "    Explorer reiniciado." -ForegroundColor Green
} else {
    Write-Host "    Pulando reinicio do Explorer." -ForegroundColor Yellow
}

Write-Host "---"
Write-Host "Sucesso! Algumas alteracoes precisam de REINICIALIZACAO para funcionar." -ForegroundColor Green
$resposta = Read-Host "Deseja reiniciar o computador agora? (S/N)"
if ($resposta -eq "S" -or $resposta -eq "s") {
    Restart-Computer -Force
}
