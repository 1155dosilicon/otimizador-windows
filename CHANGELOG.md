# Changelog — otimizador.ps1

## [3.4.1] — 2026-11-24

### Corrigido
- **EXE abria janela preta (bug crítico da 3.4):** `build-exe.ps1` passava `-noOutput` e `-noError` para o `ps2exe`. Essas flags **não** controlam a geração de arquivos `.log`/`.err` (como o comentário do script sugeria): na documentação e no código do `ps2exe`, elas removem a saída padrão e de erro do executável — o método `Write` do host (usado pelo `Write-Host`) é gerado vazio. Resultado: o `.exe` executava as 19 otimizações corretamente, mas **não desenhava nada na tela**, deixando os prompts de `Read-Host` invisíveis e travando a janela no fim. Removidas as duas flags.
- **Janela fechava ao terminar:** adicionada pausa final (`Read-Host` "Pressione ENTER") para o usuário conseguir ler o resultado antes da janela fechar.

### Nota
- O `otimizador.ps1` em si **não** tinha defeito nesta versão. O problema era exclusivamente do build.

## [3.4] — 2026-11-23

### Adicionado
- **Nova otimização #18 — Serviços desnecessários:** Desativa `WSAIFabricSvc`, `InventorySvc`, `whesvc`, `DPS`, `WdiSystemHost`, `WdiServiceHost`, `TrkWks`, `SSDPSRV`, `lmhosts`, `iphlpsvc` e `AMD Crash Defender Service`. `StiSvc` e `LanmanServer` só são desativados se o PC não tiver scanner nem pastas compartilhadas. Salva backup em `%ProgramData%\OtimizadorWindows` e, quando a chave do serviço só aceita escrita da conta SISTEMA, aplica via tarefa agendada temporária.
- **Nova otimização #19 — Agrupar svchost:** Define `SvcHostSplitThresholdInKB` acima da RAM instalada, fazendo o Windows agrupar serviços em menos processos `svchost` (testado: 132 → 73 processos).
- **`reverter-servicos.ps1`:** Restaura os serviços e o svchost a partir do backup. Também anexado às releases.

### Removido
- **Cortana (antiga #6):** O app foi descontinuado pela Microsoft no Windows 10 e 11. A política `AllowCortana` foi mantida dentro da otimização do Bing (#4).
- **Ajustes de Rede (antiga #11):** `autotuninglevel=normal` e `rss=enabled` já são o padrão do Windows; a seção não alterava nada.
- **Desativar compressão de memória (antiga #2):** A compressão é útil em PCs com pouca RAM; o Windows volta a gerenciá-la normalmente.

### Alterado
- **#2 — SysMain inteligente:** Detecta o tipo do disco do sistema. Com HDD, ou com tipo não identificado, o SysMain é mantido. Com SSD, só é desativado se houver 16 GB de RAM ou mais, pois o SysMain também gerencia a compressão de memória.
- **#11 — Plano de energia:** Agora ativa **Desempenho Máximo** (Ultimate Performance). Reaproveita um plano existente, cria a partir do modelo oculto se necessário e só cai para Alto Desempenho se o PC bloquear o Máximo.
- Otimizações renumeradas (continuam 19 no total).

## [3.3] — 2026-08-12

### Corrigido
- **Ajustes de Rede (#11):** Corrigida a invocação do `netsh`. O comando anterior passava a string inteira como um único argumento entre aspas para o executável, causando falhas recorrentes com a mensagem "comando não encontrado".
- **Compilação EXE (`build-exe.ps1`):** Removido o argumento `-noConsole` do `ps2exe`. A ausência de console ao executar o `.exe` impedia o usuário de acompanhar o progresso e fazia os prompts do `Read-Host` travarem ou falharem sem interface.
- **Limpeza de arquivos temporários (#15):** Corrigido o contador de erros. Diretórios removidos não geram mais falsos positivos nos itens contidos, e adicionado o parâmetro `-LiteralPath` para prevenir erros com nomes de arquivos contendo colchetes `[...]`.
- **Game Overlay (#5):** Adicionadas as configurações `GameDVR_Enabled` e `GameDVR_FSEBehaviorMode` em `HKCU:\System\GameConfigStore` para suprimir popups do `ms-gamingoverlay` no Windows 10/11.
- **Busca do Bing (#4):** Adicionadas as chaves de política `DisableSearchBoxSuggestions` e `DisableCloudSearch` para efetivamente desativar a busca do Bing no Menu Iniciar do Windows 10 (2004+) e Windows 11.
- **Plano de Energia (#13):** Adicionado fallback com `powercfg -duplicatescheme` caso o esquema de Alto Desempenho esteja oculto ou ausente no sistema (comum em notebooks/Modern Standby).

### Alterado
- **Feedback no Terminal (#3, #4, #5):** Adicionadas mensagens de confirmação visual em verde (`[>] ... desativado.`) nas otimizações de Telemetria, Bing e Game Overlay, padronizando com os demais 16 itens.
- **Telemetria (#3):** Incluída a parada e desativação do serviço `dmwappushservice` além do `DiagTrack`.
- **Dicas e Sugestões (#8):** Incluídas as chaves `SystemPaneSuggestionsEnabled` e `SubscribedContent-338388Enabled` para cobrir recomendações no menu Iniciar do Windows 11.
- **CrossDeviceResume (#18):** Removida instrução redundante e variável não utilizada `$taskExists`.

## [3.2] — 2026-06-27

### Adicionado
- **Nova otimização #19 — Remover Home e Galeria:** Desafixa os CLSIDs `{f874310e-b6b7-47dc-bc84-b9e6b38f5903}` (Home) e `{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}` (Galeria) do painel de navegação do Explorer no Windows 11 24H2. (Integração do script `rqa.ps1`)

## [3.1] — 2026-06-26

### Adicionado
- **Nova otimização #18 — CrossDeviceResume:** Cria tarefa agendada (`schtasks`) que mata `CrossDeviceResume.exe` a cada logon (Windows 11 — cross-device/Recall).

## [3.0] — 2026-06-19

### Adicionado
- **Nova otimização #16 — Menu de contexto clássico:** Desativa o menu de contexto moderno do Windows 11 via CLSID `{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}`, restaurando o menu clássico (shift+F10 / "Mostrar mais opções").
- **Nova otimização #17 — Remover Acesso Rápido:** Remove o Acesso Rápido da navegação do Explorer, define "Este Computador" como padrão ao abrir, e desativa arquivos recentes e pastas frequentes.

## [2.0] — 2026-05-22

### Corrigido
- **Rede (#11):** Removido `netsh int tcp set global chimney=enabled` (obsoleto desde o Windows 10 1709). Era a causa dos avisos no terminal e o comando nunca era aplicado.
- **Rede (#11):** `try/catch` substituído por verificação de `$LASTEXITCODE` — o catch antigo nunca capturava falhas do `netsh`, então o script mostrava "aplicado" mesmo quando falhava.
- **Hibernação (#9):** `try/catch` substituído por `Start-Process -PassThru` para capturar o exit code real do `powercfg`.
- **Plano de energia (#13):** GUID extraído com regex em vez de `split` por espaços (quebrava em sistemas com idioma não-inglês).
- **Plano de energia (#13):** Adicionado fallback para buscar também "Ultimate Performance".
- **Limpeza de temp (#15):** Itens em uso agora são ignorados silenciosamente em vez de poluir o terminal com centenas de erros. Contador exibe quantos foram pulados.

### Alterado
- **Explorer:** Agora pergunta antes de reiniciar o Explorer, com opção de pular (`S/N`).

## [1.0] — versão original
- Versão inicial com 15 otimizações para Windows 10/11.
