<p align="center">
  <img src="https://img.shields.io/badge/versão-3.4.1-blue?style=for-the-badge" alt="Versão 3.4.1">
  <img src="https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows 10 | 11">
  <img src="https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white" alt="PowerShell 5.1+">
  <img src="https://img.shields.io/badge/licença-MIT-green?style=for-the-badge" alt="MIT License">
</p>

<h1 align="center">⚡ Otimizador Windows</h1>

<p align="center">
  Script de otimização pós-instalação do Windows 10/11 com foco em <b>desempenho</b> e <b>privacidade</b>.<br>
  Disponível como <b>.EXE</b> (clique e pronto) ou <b>.PS1</b> (PowerShell tradicional).
</p>

---

## ⚡ Como usar (recomendado)

### 🖱️ Opção 1 — EXE (a mais fácil)

1. Baixe o **`otimizador.exe`** na [última release](https://github.com/1155dosilicon/otimizador-windows/releases/latest)
2. Clique com o botão direito → **Executar como administrador**
3. O UAC abre automaticamente. Confirme e pronto.

> Não precisa abrir terminal, digitar comandos nem liberar política de execução.

### 🖥️ Opção 2 — PowerShell (avançado)

1. Abra o **PowerShell como Administrador**
2. Libere a execução de scripts:
   ```powershell
   Set-ExecutionPolicy Unrestricted -Scope Process -Force
   ```
3. Execute:
   ```powershell
   .\otimizador.ps1
   ```
4. Ao final, responda `S` para reiniciar o PC ou `N` para depois.

#### 🛠️ Gerar o EXE você mesmo

```powershell
.\build-exe.ps1
```

> O script instala o módulo `ps2exe` automaticamente se necessário.

---

## 📋 O que o script faz — 19 otimizações

| # | Ícone | Otimização | Descrição |
|---|:---:|-----------|------------|
| 1 | 🧠 | Mitigações de CPU | Desativa Spectre/Meltdown — ganho real de desempenho |
| 2 | 💾 | SysMain inteligente | Desativa o SysMain só com SSD e 16 GB+ de RAM; em HDD ou pouca RAM ele é mantido |
| 3 | 🔒 | Telemetria | Bloqueia coleta de dados e DiagTrack |
| 4 | 🔍 | Busca do Bing | Remove Bing e Cortana da pesquisa do menu Iniciar |
| 5 | 🎮 | Game Overlay | Desativa captura de tela e avisos (Win+G) |
| 6 | 🎮 | Serviços Xbox | Para XblAuth, GameSave, NetApi e GipSvc |
| 7 | 🚫 | Dicas e Sugestões | Remove anúncios e recomendações do sistema |
| 8 | 💤 | Hibernação | Remove `hiberfil.sys` — libera GBs de disco |
| 9 | 📡 | P2P de Updates | Desativa Otimização de Entrega (economiza banda) |
| 10 | 📱 | Apps em segundo plano | Impede execução desnecessária em background |
| 11 | ⚡ | Plano de energia | Ativa Desempenho Máximo (cria o plano se estiver oculto; fallback para Alto Desempenho) |
| 12 | 📰 | Widgets | Desativa Widgets (Windows 11) |
| 13 | 🧹 | Arquivos temporários | Remove lixo do TEMP e `C:\Windows\Temp` |
| 14 | 🖱️ | Menu de contexto Win11 | Restaura o menu clássico (estilo Windows 10) |
| 15 | 📁 | Acesso Rápido | Remove do Explorer e abre em "Este Computador" |
| 16 | 🔄 | CrossDeviceResume | Mata CrossDeviceResume.exe via tarefa agendada (Recall/Cross-device) |
| 17 | 🏠 | Home e Galeria | Remove "Home" e "Galeria" do painel de navegação do Explorer (Windows 11 24H2) |
| 18 | 🧩 | Serviços desnecessários | Desativa IA do Windows, telemetria de compatibilidade, diagnósticos, UPnP, NetBIOS, túneis IPv6 e mais (com backup) |
| 19 | 📉 | Agrupar svchost | Volta a agrupar serviços em menos processos `svchost` (~metade dos processos) |

### 🧩 Serviços desativados (#18)

| Serviço | Função |
|---------|--------|
| `WSAIFabricSvc` | Componentes de IA do Windows (Copilot/Recall) |
| `InventorySvc`, `whesvc` | Telemetria de compatibilidade e "experiências otimizadas" |
| `DPS`, `WdiSystemHost`, `WdiServiceHost` | Solucionador de problemas do Windows |
| `TrkWks` | Rastreamento de links em rede corporativa |
| `SSDPSRV`, `lmhosts` | Descoberta UPnP e NetBIOS |
| `iphlpsvc` | Túneis IPv6 (Teredo/6to4/IP-HTTPS) |
| `AMD Crash Defender Service` | Coleta de crash do driver AMD (se existir) |
| `StiSvc` | Scanners/WIA — **só se nenhum scanner for detectado** |
| `LanmanServer` | Compartilhar pastas — **só se nenhuma pasta estiver compartilhada** |

> O estado original é salvo em `%ProgramData%\OtimizadorWindows\backup-servicos.csv` na primeira execução.
> Se alguma chave só aceitar escrita da conta SISTEMA, o script aplica automaticamente via tarefa temporária.

---

## ⚠️ Avisos importantes

- 🔓 **Remove correções de vulnerabilidades de CPU (Spectre/Meltdown)** — use por sua conta e risco. Não recomendado para servidores ou máquinas corporativas.
- 💤 A **hibernação será desativada** — o modo hibernar some, mas o arquivo `hiberfil.sys` (que ocupa GBs) é removido.
- 🧩 Com os serviços do #18 desativados, o **solucionador de problemas** do Windows e **VPNs/jogos que dependem de Teredo** podem não funcionar. Use `reverter-servicos.ps1` se precisar.
- 🔄 Algumas alterações exigem **reinicialização** para ter efeito completo.
- 💾 Recomenda-se **criar um ponto de restauração** antes de executar.

---

## ↩️ Reverter alterações

| Otimização | Como reverter |
|------------|---------------|
| Mitigações CPU | `FeatureSettingsOverride` = 0 (HKLM) |
| Telemetria | `AllowTelemetry` = 1, reativar DiagTrack |
| Hibernação | `powercfg -h on` |
| SysMain | `Set-Service SysMain -StartupType Automatic` |
| Plano de energia | Painel de Controle > Opções de Energia > Equilibrado |
| Serviços Xbox | `Set-Service -StartupType Manual` |
| Menu de contexto Win11 | Deletar `HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}` |
| Acesso Rápido | `HubMode` = 0, `LaunchTo` = 0 no Explorer\Advanced |
| CrossDeviceResume | Deletar tarefa: `schtasks /delete /tn "\Microsoft\Windows\Shell\Kill CrossDeviceResume.exe" /f` |
| Home e Galeria | `System.IsPinnedToNameSpaceTree` = 1 nos CLSIDs `{f874310e-...}` e `{e88865ea-...}` (HKCU) |
| Serviços e svchost (#18, #19) | Executar `reverter-servicos.ps1` (ver abaixo) |

### 🧩 Reverter serviços e svchost

Baixe o **`reverter-servicos.ps1`** na [última release](https://github.com/1155dosilicon/otimizador-windows/releases/latest) e, no **PowerShell como Administrador**:

```powershell
Set-ExecutionPolicy Unrestricted -Scope Process -Force
.\reverter-servicos.ps1
```

Ele restaura cada serviço e o agrupamento do svchost a partir do backup salvo em `%ProgramData%\OtimizadorWindows\backup-servicos.csv`. Reinicie o PC em seguida.

---

## 📦 Requisitos

- ✅ Windows 10 ou Windows 11 (64-bit)
- ✅ PowerShell 5.1+
- ✅ Executar como **Administrador**

---

## 📄 Licença

MIT — veja o arquivo [LICENSE](LICENSE).
