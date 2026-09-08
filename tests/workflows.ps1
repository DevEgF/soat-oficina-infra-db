$ErrorActionPreference = 'Stop'

$ci = Get-Content -LiteralPath '.github/workflows/ci.yml' -Raw
$deploy = Get-Content -LiteralPath '.github/workflows/deploy.yml' -Raw
$destroy = Get-Content -LiteralPath '.github/workflows/destroy.yml' -Raw

foreach ($required in @('terraform fmt -check -recursive', 'terraform validate', 'terraform test', 'tflint --recursive', 'framework: terraform')) {
    if ($ci -notmatch [regex]::Escape($required)) {
        throw "CI workflow is missing: $required"
    }
}

if ($ci -match 'id-token:\s*write') {
    throw 'CI workflow must not request an AWS identity token'
}

foreach ($required in @('id-token: write', 'group: infra-db-shared', 'cancel-in-progress: false', 'terraform plan -input=false -out=tfplan', 'terraform apply -input=false tfplan')) {
    if ($deploy -notmatch [regex]::Escape($required)) {
        throw "deploy workflow is missing: $required"
    }
}

foreach ($required in @('DESTROY-soat-oficina-db', 'create-db-snapshot', 'copy-db-snapshot', 'delete-db-snapshot', '--kms-key-id alias/aws/rds', 'db-snapshot-available', 'db-snapshot-deleted', 'disable-protection.tfplan', 'destroy.tfplan', 'snapshot_arn')) {
    if ($destroy -notmatch [regex]::Escape($required)) {
        throw "destroy workflow is missing: $required"
    }
}

$snapshotIndex = $destroy.IndexOf('create-db-snapshot')
$copyIndex = $destroy.IndexOf('copy-db-snapshot')
$deleteSourceIndex = $destroy.IndexOf('delete-db-snapshot')
$disableProtectionIndex = $destroy.IndexOf('disable-protection.tfplan')
if ($snapshotIndex -lt 0 -or $copyIndex -lt 0 -or $deleteSourceIndex -lt 0 -or $disableProtectionIndex -lt 0 -or
    $snapshotIndex -gt $copyIndex -or $copyIndex -gt $deleteSourceIndex -or $deleteSourceIndex -gt $disableProtectionIndex) {
    throw 'the final snapshot must be copied to alias/aws/rds and its source removed before deletion protection is disabled'
}
