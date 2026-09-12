# Registro de execução e encerramento AWS - Banco de dados gerenciado

## Por que o serviço AWS foi encerrado

O ambiente foi criado temporariamente para integração, validação e gravação da Fase 3. Após concluir a demonstração e preservar o vídeo e as evidências, o responsável encerrou a conta AWS para evitar custos recorrentes de manter a infraestrutura ligada.

A limpeza começou somente depois da verificação do vídeo. Durante esse processo, o acesso à AWS foi bloqueado e a tela de login informou suspensão; posteriormente, o responsável confirmou que encerrou a conta. O encerramento foi informado pelo titular. Não foi possível consultar independentemente o inventário final, e este documento não afirma que todos os recursos foram individualmente destruídos ou que o saldo final foi auditado.

## Estado atual de CI/CD e acesso

- Os workflows que acessam a AWS foram desabilitados manualmente no GitHub nos quatro repositórios; os arquivos permanecem versionados como documentação executável da entrega.
- Os workflows de CI permanecem ativos para testes e validações sem deploy AWS. Nenhum workflow de nuvem deve ser reativado automaticamente por esta documentação.
- Os links de Actions abaixo são evidências históricas de execução, não endpoints ativos. O ambiente AWS foi encerrado após a demonstração e não é oferecido para acesso atual do avaliador.
- Os quatro repositórios são públicos. O acesso de escrita do usuário `soat-architecture` foi reconfirmado nos quatro, sem convite pendente.
- Código, documentação e histórico de PRs foram preservados. Não é necessário reabrir a conta apenas para ler os repositórios ou assistir ao vídeo preservado.

Uma futura implantação dependerá de decisão explícita do responsável, conta acessível, revisão de custos/permissões e novos planos Terraform. Não reaplicar planos históricos nem presumir recursos ainda existentes.

## O que foi executado

- Amazon RDS PostgreSQL foi provisionado por Terraform e usado pelas aplicações e Lambdas em homologação e produção.
- A última consulta registrada retornou PostgreSQL 16.13, estado available, acesso público desabilitado, armazenamento criptografado e proteção contra exclusão habilitada.
- A aplicação usa Flyway e schemas hml/prod para isolamento lógico na instância compartilhada. As jornadas reais de autenticação e OS passaram nos dois ambientes.
- O rollback da aplicação preservou uma OS já entregue, confirmando persistência dos dados durante a troca de versão da aplicação.

### Evidências públicas

- [Deploy do banco em main](https://github.com/DevEgF/soat-oficina-infra-db/actions/runs/34662017166).
- [Aplicação usando o banco em produção](https://github.com/DevEgF/soat-oficina-app/actions/runs/34665628443).
- [Autenticação integrada com o banco](https://github.com/DevEgF/soat-oficina-auth/actions/runs/34664445948).

### Limite da remoção

O workflow de destruição do RDS não foi executado nesta etapa de encerramento. A sessão AWS deixou de funcionar durante a limpeza anterior, e o responsável encerrou a conta. Não há confirmação de exclusão da instância, de criação do snapshot final nessa etapa ou de inventário vazio após o encerramento.

As instruções de snapshot/proteção contra exclusão do runbook documentam o procedimento previsto; não são evidência de que ele foi executado. Os estados e arquivos locais existentes foram preservados pelo responsável, sem publicação de material sensível.

## Registros dos quatro componentes

- [Aplicação](https://github.com/DevEgF/soat-oficina-app/blob/main/docs/delivery/encerramento-aws.md)
- [Autenticação](https://github.com/DevEgF/soat-oficina-auth/blob/main/docs/delivery/encerramento-aws.md)
- [Fundação EKS](https://github.com/DevEgF/soat-oficina-infra-k8s/blob/main/docs/delivery/encerramento-aws.md)
- [Banco RDS](https://github.com/DevEgF/soat-oficina-infra-db/blob/main/docs/delivery/encerramento-aws.md)

As datas dos workflows podem aparecer em 12/09/2026 UTC; a demonstração foi gravada em 11/09/2026 no horário de Brasília.
