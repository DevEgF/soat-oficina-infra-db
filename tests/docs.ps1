$ErrorActionPreference = 'Stop'

$docs = (Get-Content -LiteralPath @('README.md', 'docs/er.md', 'docs/decision.md', 'docs/runbook.md') -Raw) -join "`n"

foreach ($term in @('db.t4g.micro', 'Single-AZ', 'schema hml', 'schema prod', 'terraform destroy', 'master_secret_arn', 'alias/aws/rds')) {
    if ($docs -notmatch [regex]::Escape($term)) {
        throw "missing documentation term: $term"
    }
}

foreach ($forbidden in @('password\s*=', 'get-secret-value', 'batch-get-secret-value')) {
    if ($docs -match $forbidden) {
        throw "documentation contains forbidden secret handling pattern: $forbidden"
    }
}

foreach ($entity in @('clientes', 'veiculos', 'ordens_servico', 'servicos_catalogo', 'pecas', 'reservas_peca_os')) {
    if ($docs -notmatch [regex]::Escape($entity)) {
        throw "ER documentation is missing entity: $entity"
    }
}
