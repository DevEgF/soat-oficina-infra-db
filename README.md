# soat-oficina-infra-db

Infraestrutura Terraform do PostgreSQL gerenciado da Fase 3. O módulo cria uma
instância RDS privada e compartilhada, e a aplicação mantém o isolamento lógico
por `schema hml` e `schema prod` com Flyway.

## Arquitetura

- PostgreSQL 16 em `db.t4g.micro`, Single-AZ, 20 GiB gp3 e autoscaling até 100 GiB.
- Acesso privado na VPC, porta 5432 liberada somente para os security groups do
  EKS e das Lambdas.
- TLS obrigatório com `rds.force_ssl=1`, criptografia por chave KMS gerenciada
  pelo projeto e logs retidos por 365 dias.
- Credencial mestre criada e mantida pelo RDS no Secrets Manager. O Terraform
  expõe somente `master_secret_arn`; os workloads resolvem o conteúdo em runtime.
- Alarmes 2-de-3 para CPU, espaço livre e conexões, publicados no SNS da fundação.

O contrato canônico entre repositórios está em
[`soat-oficina-app/docs/architecture/integration-contracts.md`](https://github.com/DevEgF/soat-oficina-app/blob/develop/docs/architecture/integration-contracts.md).

## Validação local

Requer Terraform 1.11 ou posterior, TFLint e Checkov:

```powershell
terraform init -backend=false -input=false
terraform fmt -check -recursive
terraform validate
terraform test
tflint --recursive
checkov -d . --framework terraform --quiet
pwsh -File tests/workflows.ps1
pwsh -File tests/docs.ps1
```

## Plano e aplicação

O bucket é criado pela fundação e informado sem armazenar credenciais estáticas:

```powershell
terraform init -input=false -backend-config="bucket=<TF_STATE_BUCKET>" -backend-config="region=us-east-1"
terraform plan -input=false -var="state_bucket=<TF_STATE_BUCKET>" -out=tfplan
terraform apply -input=false tfplan
```

Em CI, `develop` e `main` revalidam o mesmo state compartilhado. O grupo de
concorrência `infra-db-shared` impede aplicações simultâneas.

## Outputs

| Output | Uso |
|---|---|
| `database_endpoint` | Host privado consumido por app e auth; metadado sensível |
| `database_port` | Porta estável 5432 |
| `database_name` | Database estável `oficina` |
| `master_secret_arn` | Referência ao segredo gerenciado, nunca seu conteúdo |
| `rds_security_group_id` | Evidência do isolamento de rede |
| `db_subnet_group_name` | Evidência das subnets privadas |
| `database_alarm_names` | Alarmes técnicos do banco |

Consulte [o runbook](docs/runbook.md) para verificação e lifecycle. O workflow
manual protegido deve ser usado no encerramento; não execute `terraform destroy`
diretamente durante a operação normal.

Antes de remover a chave KMS do banco, o workflow copia o snapshot final para a
chave AWS gerenciada `alias/aws/rds`, valida a cópia e remove o snapshot fonte.
Assim, o artefato de restauração permanece legível após o encerramento da stack.

O segredo gerenciado do RDS usa a chave KMS do banco. A policy da aplicação
permite leitura por HTTPS e descriptografia apenas desse segredo via Secrets
Manager. Aplique as permissões atualizadas de `infra-k8s` antes do deploy do
banco; a role de deploy pode criar o segredo gerenciado, mas não ler seu valor.
