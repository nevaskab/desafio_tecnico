# Passo 2 - O Coração da Usina (Erlang OTP & ETS)

## 1. Implementação
* Criação do processo `DesafioTecnico.Engine.MachineMonitor` utilizando o comportamento `GenServer`.
* Inicialização de uma tabela em memória **ETS** do tipo `:set` com a flag `read_concurrency: true`.
* Implementação do padrão de ingestão assíncrona via `cast`.
* Mecanismo de **Write-Behind** (Escrita Posterior) disparado via mensagens internas `:info` a cada 5 segundos.

## 2. Arquitetura
Ela deixou de ser estritamente "Database-First" para ser "Memory-First". 
* O estado "quente" (tempo real) vive exclusivamente no ETS.
* O estado "frio" (histórico/persistência) é sincronizado em lotes para o SQLite.
* Introdução de um rastreador de `dirty_ids` no estado do GenServer para garantir que apenas máquinas que receberam pulsos sejam processadas no flush, otimizando o I/O.

## 3. Trade-offs e Decisões

### Estratégia de Supervisão: `one_for_one`
* **Defesa:** O Monitor é um processo vital, mas isolado. Se ele falhar devido a um payload corrompido, o Supervisor o reinicia. 
* **Trade-off:** Como o ETS pertence ao processo, um crash limpa o cache de memória. No entanto, como o sistema é imune a picos e o SQLite guarda o histórico, o monitor reinicia, busca o último estado no banco e volta a operar. A disponibilidade da ingestão é priorizada sobre a retenção de microssegundos de dados voláteis.

### Estratégia de Banco: Write-Behind vs Write-Through
* **Decisão:** Write-Behind.
* **Motivo:** Gravar no SQLite a cada milissegundo causaria o travamento do sistema por contenção de escrita no arquivo do banco. Ao agrupar as mudanças e gravar a cada 5 segundos, reduzimos drasticamente o número de transações no disco, resolvendo o problema original de "delay de minutos".

## Defesa da Estrutura ETS
  * **Tabela:** `:w_core_telemetry_cache` (Tipo `:set`).
  * **Estrutura:** `{node_id, status, event_count, last_payload, timestamp}`.
  * **Justificativa:** O uso de uma tupla plana no ETS otimiza a serialização e desserialização da BEAM. O `node_id` como chave primária garante acesso `O(1)`, permitindo que o sistema encontre qualquer máquina instantaneamente mesmo com milhares de registros.

## Estratégia de Supervisão
  * **Absorção de Tsunami:** O GenServer utiliza `handle_cast` para garantir que o processo de rede que envia os dados não fique esperando a resposta (non-blocking I/O).
  * **Mecanismo Write-Behind:** Implementamos um estado de "Dirty IDs" dentro do GenServer. Isso evita que o sistema tente sincronizar dados que não mudaram, reduzindo drasticamente o overhead de I/O no SQLite.
  * **Integridade:** Caso o servidor reinicie, o SQLite contém o último estado persistido do ciclo de 5 segundos anterior, cumprindo o requisito de persistência de histórico.