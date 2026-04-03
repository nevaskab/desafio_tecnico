# Passo 3 - A Sala de Controle (Design System e LiveView)

## 1. Implementação
  * Dashboard em tempo real utilizando `Phoenix.LiveView`.
  * Integração com a camada de memória: o estado inicial é carregado via `tab2list` do ETS `:w_core_telemetry_cache`.
  * Reatividade via `Phoenix.PubSub` para atualizações dinâmicas de falhas.
  * Componentes visuais puros em HEEx com classes condicionais (Tailwind/CSS nativo) para alertas visuais (efeito pulse).

## 2. Arquitetura
  * A interface deixou de ser uma página estática que faz polling no banco.
  * O fluxo de dados agora é: `MachineMonitor (ETS) -> PubSub -> LiveView -> Browser (WebSocket)`.
  * O banco de dados (SQLite) foi completamente removido do caminho crítico da interface de Monitoramento.

## 3. Trade-offs e Decisões

### Como evitar gargalos no PubSub?
  * **Filtragem na Fonte:** O `MachineMonitor` não emite mensagens PubSub para cada evento recebido. Ele compara o `new_status` com o `last_status` e só faz o `broadcast` quando ocorre uma **transição de estado** (ex: Online para Error).
  * **Motivo:** Se tivessem 1.000 máquinas enviando 10 eventos/segundo, seriam 10.000 mensagens PubSub por segundo. Com a filtragem, só é emitido mensagens quando algo realmente importante acontece, reduzindo o tráfego à margem de 99%.

### Design System: HEEx Puro
  * **Decisão:** Uso de componentes funcionais HEEx e Tailwind CSS.
  * **Motivo:** Bibliotecas de terceiros trazem overhead de JavaScript e CSS que poderiam degradar a performance em telas com centenas de máquinas. O HEEx permite que o Phoenix envie apenas "diffs" de poucos bytes, garantindo que a tela "pisque" instantaneamente mesmo em conexões instáveis.

### Performance de Renderização
  * **Decisão:** O estado no LiveView mantém apenas o necessário para a visualização (`id`, `status`, `count`).
  * **Trade-off:** Não enviamos o `last_payload` bruto (JSON) para o browser a menos que o usuário solicite (ex: clicando na máquina). Isso economiza memória no processo do LiveView e banda de rede.