# Planejamento

Esse é o meu docs, onde detalho as ações tomadas para a realização do desafio. Antes de "meter a mão na massa" anotei os principais pontos em um arquivo.txt, idealizei a estrutura e assim segui alguns passos de planejamento: 
  * Entender os pontos principais e as exigências do desafio
  * Buscar conhecimentos sobre Elixir e Phoenix
  * Instalar ferramentas necessárias
  * E, agora sim, colocar em prática conhecimentos adquiridos em minha formação sobre desenvolvimento back-end, front-end, banco de dados e entre outros.

## Anotações no arquivo .txt:
```
Planta 42 - Desafio Técnico

Problema: sobrecarga de sistema, delay de minutos e falsos positivos

Missão:
  - Construir motor em tempo real
  - Sistema: roda localmente, usando banco de dados embutido e imune a picos de tráfego.
  - Tela deve piscar em tempo real na falha de uma máquina
  - Histórico salvo caso o servidor reinicie

Stack e Restrições:
  - Linguagem e Framework: Elixir + Phoenix LiveView
  - Banco de Dados: SQLite local (estritamente proibido o uso de dependências externas)
  - Autenticação: Gerada exclusivamento via phx.gen.auth
  - Estado e Cache: Uso obrigatório de ETS e processo OTP para fluxo de dados
  - Design System: Componentes HEEx puros (nada de bibliotecas pesadas de UI de terceiros)
  - Infraestrutura: Uma release Elixir Pura (rodando em dockerfile simples)

Regra de ouro:
  - Sempre que houver evolução concluída, precisa criar um arquivo markdown em /docs/drafts/ (ex: 
    /docs/drafts/step-1-foundation.md) contendo o que foi implementado, o que mudou na arquitetura,
    trade-offs e o porquê das decisões (principalmente sobre concorrência e o banco)


Arquitetura principal

desafio_tecnico/
├── config/
│   ├── config.exs
│   ├── dev.exs
│   └── runtime.exs
├── docs/
│   └── drafts/            #documentacão
│       ├── step-1-planejamento.md
│       └── step-2-memory-engine.md
├── lib/
│   ├── desafio_tecnico/
│   │   ├── accounts/
│   │   ├── accounts.ex
│   │   ├── application.ex
│   │   ├── repo.ex
│   │   └── engine/        #genservers e ETS
│   │       ├── machine_monitor.ex
│   │       └── db_worker.ex
│   ├── desafio_tecnico_web/
│   │   ├── components/
│   │   ├── controllers/
│   │   ├── live/
│   │   └── endpoint.ex    #conexao hhtps e websockets
├── priv/
│   └── repo/
│       └── migrations/     #scripts para tabelas
├── Dockerfile
└── mix.exs
```