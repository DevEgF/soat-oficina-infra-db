# Runbook do PostgreSQL gerenciado

## Criar ou atualizar

1. Confirme a identidade AWS e a região `us-east-1`.
2. Confirme que `infra-k8s/terraform.tfstate` existe no bucket compartilhado.
3. Execute o Completion Gate descrito no README.
4. Inicialize o backend, gere `tfplan`, revise-o e aplique exatamente esse plano.
5. Aguarde o RDS ficar `available` antes de implantar migrations ou workloads.

O caminho normal é o workflow `deploy`, autenticado por OIDC e serializado pelo
grupo `infra-db-shared`.

## Verificar sem ler credenciais

Use somente APIs de metadados:

```powershell
aws rds describe-db-instances --db-instance-identifier soat-oficina-db --region us-east-1
aws secretsmanager describe-secret --secret-id <master_secret_arn> --region us-east-1
aws cloudwatch describe-alarms --alarm-name-prefix soat-oficina-db- --region us-east-1
```

Confirme `available`, PostgreSQL 16, `PubliclyAccessible=false`, storage
criptografado, deletion protection ativa, subnet group privado e os três alarmes.
O ARN pode ser redigido nos relatórios; o conteúdo do segredo nunca deve entrar
em terminal, log, output Terraform ou variável do GitHub.

## Diagnosticar falha de conexão

1. Confirme que a instância está `available` e que o endpoint usado pertence ao
   output `database_endpoint` do state atual.
2. Confirme DNS e rota a partir do pod ou da Lambda dentro da VPC.
3. Verifique se a origem usa o security group esperado e se a regra 5432 aponta
   para ele, sem substituir a origem por um CIDR amplo.
4. Confirme que o workload recebeu o ARN e que sua Pod Identity ou execution role
   possui acesso somente ao segredo exato. A chave KMS do banco também protege
   o segredo gerenciado: a aplicação precisa de `kms:Decrypt` nessa chave, via
   Secrets Manager e com o contexto `SecretARN` limitado ao mesmo segredo.
5. Confirme o schema selecionado (`hml` ou `prod`) e o histórico do Flyway.
6. Consulte os logs do PostgreSQL e os alarmes de CPU, storage e conexões.

## Encerrar com snapshot final

Use o workflow manual `destroy` e informe `DESTROY-soat-oficina-db`. Ele executa,
na ordem: snapshot fonte datado, cópia criptografada pela chave AWS gerenciada
`alias/aws/rds`, validação da cópia, remoção do snapshot fonte, plano salvo para
desativar deletion protection, plano completo de destruição e aplicação do plano
salvo. O ARN da cópia final e os dois planos ficam anexados como evidência. A
cópia não depende da chave KMS do Terraform, cuja exclusão é agendada no destroy.

Não use `terraform destroy` diretamente: isso contorna o guardrail que comprova o
snapshot. Destrua auth e app antes do banco, e o banco antes de infra-k8s, pois a
policy do segredo pertence a este state e está anexada a uma role da fundação.

## Limites de restauração

O backup automatizado cobre somente um dia e o snapshot final é pontual. Uma
restauração cria outra instância e exige reconfigurar endpoint, security groups e
consumidores antes do corte. Restaure primeiro em ambiente isolado, valide o
histórico Flyway e testes funcionais, e só depois promova o novo endpoint.
