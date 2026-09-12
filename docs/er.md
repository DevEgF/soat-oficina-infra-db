# Modelo relacional

O database `oficina` contém o mesmo conjunto de tabelas no `schema hml` e no
`schema prod`. Cada execução do Flyway seleciona exatamente um schema, evitando
mistura de dados entre os ambientes mesmo com uma única instância acadêmica.

```mermaid
erDiagram
    clientes ||--o{ veiculos : possui
    clientes ||--o{ ordens_servico : solicita
    veiculos ||--o{ ordens_servico : recebe
    ordens_servico ||--o{ ordem_servico_linhas_servico : inclui
    servicos_catalogo ||--o{ ordem_servico_linhas_servico : referencia
    ordens_servico ||--o{ ordem_servico_linhas_peca : inclui
    pecas ||--o{ ordem_servico_linhas_peca : referencia
    ordens_servico ||--o{ reservas_peca_os : reserva
    pecas ||--o{ reservas_peca_os : compromete

    clientes {
        varchar id PK
        varchar documento UK
        varchar nome
        varchar email
        varchar telefone
    }
    veiculos {
        varchar id PK
        varchar cliente_id FK
        varchar placa UK
        varchar marca
        varchar modelo
        int ano
    }
    ordens_servico {
        varchar id PK
        varchar codigo_acompanhamento UK
        varchar cliente_id FK
        varchar veiculo_id FK
        varchar status
        bigint valor_total_centavos
        timestamp criado_em
        varchar observacoes_diagnostico
    }
    servicos_catalogo {
        varchar id PK
        varchar nome
        bigint preco_centavos
        int tempo_estimado_minutos
    }
    pecas {
        varchar id PK
        varchar codigo UK
        varchar nome
        bigint preco_centavos
        int quantidade_estoque
        int ponto_reposicao
    }
    ordem_servico_linhas_servico {
        varchar id PK
        varchar ordem_servico_id FK
        varchar servico_catalogo_id FK
        int quantidade
        bigint preco_unitario_centavos
    }
    ordem_servico_linhas_peca {
        varchar id PK
        varchar ordem_servico_id FK
        varchar peca_id FK
        int quantidade
        bigint preco_unitario_centavos
    }
    reservas_peca_os {
        varchar id PK
        varchar ordem_servico_id FK
        varchar peca_id FK
        int quantidade
        varchar status
    }
```

As migrations versionadas da aplicação são a fonte de verdade do DDL. Este
diagrama documenta as relações funcionais e não substitui o Flyway.
