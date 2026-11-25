# =================================================================
# BUILD SCRIPT — Converte otimizador.ps1 em .EXE via PS2EXE
# =================================================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$inputFile  = Join-Path $scriptDir "otimizador.ps1"
$outputFile = Join-Path $scriptDir "otimizador.exe"

if (!(Test-Path $inputFile)) {
    Write-Error "Arquivo '$inputFile' nao encontrado."
    exit 1
}

# Instala ps2exe se necessario
if (!(Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "[>] Instalando modulo ps2exe..." -ForegroundColor Yellow
    try {
        Install-PackageProvider -Name NuGet -Force -ForceBootstrap -Scope CurrentUser -ErrorAction Stop
        Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck -ErrorAction Stop
    } catch {
        Write-Error "Falha ao instalar ps2exe. Execute como Administrador e tente novamente."
        exit 1
    }
}

Write-Host "[>] Gerando $outputFile ..." -ForegroundColor Cyan

# Parametros:
#   -requireAdmin: embute manifest pedindo elevacao (UAC)
#   -title: nome que aparece no UAC / Task Manager
#   -version: versao do EXE
#
# ATENCAO: NAO usar -noOutput nem -noError aqui.
# Na documentacao do ps2exe essas flags significam:
#   noOutput = o executavel NAO gera saida padrao (inclui Write-Host/verbose/informacao)
#   noError  = o executavel NAO gera saida de erro (inclui warning/debug)
# Ou seja: com elas o .exe abre a janela, executa tudo e nao desenha nada na tela.
# Era exatamente esse o bug da v3.4 (janela preta, Read-Host invisivel).
# Elas NAO tem relacao com gerar arquivo .log/.err.

Invoke-ps2exe -InputFile $inputFile `
              -OutputFile $outputFile `
              -requireAdmin `
              -title "Otimizador Windows" `
              -description "Script de otimizacao pos-instalacao Windows 10/11" `
              -version "3.4.1.0" `
              -product "Otimizador Windows" `
              -company ""

if (Test-Path $outputFile) {
    $size = [math]::Round((Get-Item $outputFile).Length / 1KB, 1)
    Write-Host "    Sucesso! $outputFile ($size KB)" -ForegroundColor Green
} else {
    Write-Error "Falha ao gerar o EXE."
    exit 1
}
