# Passo 1 - O Perímetro de Segurança (Fundação e Autenticação)

## 1. Implementação
  * Inicialização da aplicação Phoenix (`desafio_tecnico`) utilizando o comando `--database sqlite3`.
  * Geração do sistema de autenticação utilizando comando nativo `phx.gen.auth` para criação do context `Accounts`.
  * Criação do isolamento de domínio, estabelecendo a base para o context `Telemetry`, separando estritamente a regra de negócios de ingestão de dados da camada de apresentação.

## 2. Arquitetura
A base segue o padrão de Contexts do Phoenix:
  * **`DesafioTecnico.Accounts`**: Gerencia o ciclo de vida e credenciais de usuários.
  * **`DesafioTecnico.Telemetry`** (Core): Domínio (isolado) que será responsável pela lógica de máquinas, estados e alertas.
  * **`DesafioTecnicoWeb`** (Interface): Consome os dados do core mas sem acessar o banco de dados diretamente para ler status de máquinas.

## 3. Trade-offs e Decisões

### Banco de Dados: SQLite (Exigido no Desafio)
  * **Decisão:** Foi utilizado adaptador `ecto_sqlite3` para banco embutido local.
  * **Motivo:** O SQLite oferece simplicidade e eficiência.
  * **Trade-off:** O SQLite opera com *file-level locks* durante operações de escrita (Write-Ahead Logging minimiza, mas não elimina o problema de concorrência massiva). Escrever no banco a cada pulso das máquinas geraria um gargalo imediato. Essa decisão técnica força e justifica a necessidade de construirmos um motor em memória (ETS) para absorver o tráfego, "aliviando" o papel do SQLite de persistência assíncrona (Write-Behind) para retenção de histórico.

### Autenticação: `phx.gen.auth`
  * **Decisão:** Uso do comando nativo ao invés de bibliotecas externas pesadas.
  * **Motivo:** Gerar o código dentro da aplicação promove controle absoluto sobre o fluxo de sessão, cookies e rotas, facilitando a customização.

### Isolamento do Phoenix
  * **Decisão:** O Phoenix é apenas a interface.
  * **Motivo:** A ingestão de telemetria ocorrerá no nível da Erlang VM (BEAM) e separar o domínio `Telemetry` garante que o motor em tempo real funcione e possa ser testado exaustivamente via terminal (IEx) ou testes unitários, mesmo se a camada web estiver inoperante.

### Modelagem de Dados e Camada de Persistência (SQLite/Ecto)
  * **Decisão:** Criação isolada dos schemas `Node` e `NodeMetric` usando `mix phx.gen.context`.
  * **Estrutura:** 
    * `node`: Armazena o registro imutável do sensor (`machine_identifier` e `location`).
    * `node_metrics`: Armazena o estado consolidado (`status`, `total_events_processed`, `last_payload`). Possui uma relação estrita de 1:1 com `nodes` garantida por um `unique_index` no banco.
  * **Motivo:** O desafio exige que o histórico seja salvo caso o servidor reinicie. Separar os dados estáticos da máquina (`nodes`) dos dados voláteis de telemetria (`node_metrics`) evita duplicação de dados e facilita o trabalho do futuro *Write-Behind* (o Worker OTP que vai pegar os dados em alta velocidade do ETS e atualizar a tabela `node_metrics` em background).