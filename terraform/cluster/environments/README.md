# environments/

One folder per environment. **No `.tf` files here — only tfvars values and backend config.**

The Terraform code in `cluster/*.tf` is the same for all environments; each env just supplies different variable values.

## Environments

| Env | Purpose | Region | VPC CIDR | Nodes | Public URL prefix | Cost/day (est) |
|---|---|---|---|---|---|---|
| `dev` | Daily development | us-east-1 | 10.10.0.0/16 | 1× t3.medium | `argo.dev.` / `demoapp.dev.` | ~$3 |
| `staging` | Pre-prod validation | us-east-1 | 10.20.0.0/16 | 2× t3.large | `argo.staging.` / `demoapp.staging.` | ~$8 |
| `qa` | Automated tests / QA | us-east-1 | 10.30.0.0/16 | 2× t3.medium | `argo.qa.` / `demoapp.qa.` | ~$5 |
| `prod` | Live traffic | us-east-1 | 10.0.0.0/16 | 2× t3.large | `argo.prod.` / `demoapp.prod.` | ~$8 |
| `dr` | Disaster Recovery (warm standby) | **us-west-2** | 10.90.0.0/16 | 1× t3.large | `argo.dr.` / `demoapp.dr.` | ~$5 |

**All envs share the same `base_domain`** (`argocd-lab.kriolu-kloud.cv`). The env name is injected as a subdomain — URLs are `<service>.<env>.<base_domain>`.

CIDRs are distinct so any two environments can be VPC-peered in the future.

## Per-env files

Each env folder contains:

```
<env>/
├── backend.hcl                 # partial backend config: key = "argoeks/<env>/terraform.tfstate"
├── terraform.tfvars.example    # committed template — safe to share
├── terraform.tfvars            # gitignored — real values with secrets
└── .gitignore
```

## Switching between environments

The `cluster/` code compiles for every env. What changes is the state (via `-backend-config`) and the values (via `-var-file`):

```bash
cd cluster/

# ── Point to the env's state ──
terraform init -reconfigure -backend-config=environments/dev/backend.hcl

# ── Plan / apply / destroy with the env's values ──
terraform plan   -var-file=environments/dev/terraform.tfvars
terraform apply  -var-file=environments/dev/terraform.tfvars
terraform destroy -var-file=environments/dev/terraform.tfvars
```

To switch to staging:

```bash
terraform init -reconfigure -backend-config=environments/staging/backend.hcl
terraform apply -var-file=environments/staging/terraform.tfvars
```

**Never skip `-reconfigure`** when switching. Otherwise Terraform keeps the previous backend key cached in `.terraform/terraform.tfstate` locally.

## What "DR" means

**Disaster Recovery** — a second copy of the infrastructure in a different AWS region, ready to take over if the primary region has an outage.

Three variants:

- **Cold DR**: state + configs only, cluster off. Cheap but takes hours to activate.
- **Warm DR** (this project's default): minimal cluster running, RDS with cross-region read-replica. ~50% of prod cost, promotable in minutes.
- **Hot DR** (active-active): identical to prod, traffic split via Route53. 2× cost, instant failover.

For failover:
1. Promote the DR RDS read-replica to primary
2. Bump `node_desired_size` in `dr/terraform.tfvars` to prod size
3. `terraform apply` on `dr/`
4. Switch Route53 to point `argocd-lab.kriolu-kloud.cv` at the DR NLB

## Golden rule

**Do not put `.tf` files in these folders.** Only tfvars + backend.hcl + .gitignore.

Adding `.tf` here would drift the code across environments — that's exactly the anti-pattern the `modules/` + `cluster/` layout avoids.
