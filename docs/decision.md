# Decisão de arquitetura do banco

## Decisão

Manter PostgreSQL 16 no Amazon RDS. O modelo existente é relacional, usa chaves
estrangeiras, transações, índices únicos e tipos nativos do PostgreSQL. RDS reduz
o trabalho operacional sem exigir reescrita das migrations ou da camada JPA.

## Segurança e operação

A instância não possui endereço público e fica em duas subnets privadas. O
security group aceita PostgreSQL apenas do EKS e das Lambdas. Dados e telemetria
são criptografados com chave KMS do projeto, TLS é obrigatório, Enhanced
Monitoring e Performance Insights estão ativos, e os logs ficam disponíveis por
365 dias. A senha não é definida em código ou variável: RDS gerencia o segredo e
somente o `master_secret_arn` atravessa os contratos entre repositórios.

## Trade-offs acadêmicos

A classe `db.t4g.micro` e Single-AZ foram escolhidas para caber no envelope de
créditos do projeto. Isso reduz disponibilidade e capacidade; não é a topologia
indicada para uma oficina em produção real. `schema hml` e `schema prod`
compartilham compute e storage, portanto picos de um ambiente podem afetar o
outro.

A retenção automatizada de backup é de um dia. Para compensar o risco no fim do
lifecycle, deletion protection começa habilitada e o workflow de destroy exige
confirmação digitada, cria um snapshot final, aguarda seu estado disponível e só
então desativa a proteção. O snapshot manual continua gerando custo até ser
removido conscientemente.

Uma evolução de produção deve usar pelo menos Multi-AZ, retenção de sete dias ou
mais, usuários separados por workload e, conforme volume e criticidade, réplicas
de leitura ou Aurora PostgreSQL.
