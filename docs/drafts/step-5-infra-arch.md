# Passo 5 - Empacotamento para o Edge (Infraestrutura)

## Estratégia de Deploy (Mix Release e Docker)
A aplicação foi empacotada utilizando a funcionalidade nativa `mix release` acoplada a uma estratégia de *Multi-stage Build* no Docker, visando segurança e otimização extrema de recursos:

1. **Estágio Builder:** Contém todos os compiladores pesados (Erlang, C, Node) necessários para gerar a release. Durante o processo, a ordem de compilação foi ajustada para suportar os padrões modernos do Phoenix: o `mix compile` é executado antes do `mix assets.deploy` para garantir a extração correta dos *Colocated JS/Hooks* (arquivos JavaScript embutidos nos componentes LiveView) pelo `esbuild`.

2. **Estágio Runner:** Uma imagem baseada em Alpine Linux ultra-leve, recebendo apenas o binário pré-compilado da aplicação. Variáveis obrigatórias para releases, como `PHX_SERVER=true`, são injetadas nesta camada para garantir a inicialização autônoma do servidor web. O código-fonte original não é transferido, blindando a propriedade intelectual.

## Orquestração e Gestão de Segredos (Docker Compose)
Seguindo os princípios do *Twelve-Factor App*, a configuração e os segredos da aplicação foram completamente desacoplados do `Dockerfile`:
* **Variáveis de Ambiente (`.env`):** Segredos críticos (como o `SECRET_KEY_BASE`) e portas são armazenados em um arquivo não-versionado.
* **Docker Compose:** Atua como orquestrador local, responsável por injetar o arquivo `.env` no contêiner durante o *startup* e gerenciar as políticas de reinicialização automática (`restart: unless-stopped`) vitais para ambientes industriais (Edge).

## Persistência e Edge Computing (SQLite)
Gerenciar a infraestrutura de um banco de dados externo (como PostgreSQL) introduz complexidade e consumo de recursos desnecessários. O uso do Ecto com SQLite embutido resolve este gargalo, porém exige cuidado com a natureza efêmera dos contêineres Docker.

**A Solução:** O caminho do banco foi parametrizado no `runtime.exs` via variável de ambiente. O `docker-compose.yml` cria um mapeamento de volume (`./data:/etc/desafio_tecnico`), garantindo que o arquivo `.db` resida fisicamente no disco da máquina hospedeira. Atualizações de imagem ou *crashes* do contêiner não resultam em perda do histórico de telemetria.

## Diagrama Arquitetural do Fluxo Final

```mermaid
graph TD
    %% Entradas
    M1(Máquina 01) -->|HTTP Post| EP[Phoenix Endpoint]
    M2(Máquina 0N) -->|HTTP Post| EP

    %% Motor
    subgraph Erlang VM [Máquina Virtual BEAM]
        EP -->|Monitor.ingest_event/2| G[GenServer: Monitor]
        
        %% O Funil
        G -->|Leitura/Escrita Atômica < 1ms| ETS[(ETS Cache em Memória)]
        G -->|Se houver mudança de status| PS((Phoenix PubSub))
        
        %% O Write-Behind
        G -.->|A cada 5 segundos| DB_WORKER[Worker de Persistência]
    end
    
    %% O Banco
    DB_WORKER -->|Batch Update/Insert| Ecto[Ecto SQLite]
    Ecto --> SQLite[(Volume Docker: planta42.db)]
    
    %% Frontend Reativo
    PS -->|Push Diff via WebSocket| LV[Dashboard LiveView]
    User((Usuário Autenticado)) <-->|Visualiza/Interage| LV