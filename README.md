# cluster-eks-argoci

GitOps platform running a containerised web application on Amazon EKS, managed entirely through Infrastructure as Code and automated CI/CD pipelines.

## Repository layout

```
cluster-eks-argoci/
├── terraform/    # AWS infrastructure (EKS, VPC, RDS, Lambda, SQS, ECR, S3 …)
├── app/          # Application source code + Docker builds + CI pipeline
├── manifests/    # Kubernetes manifests pushed by CI, watched by ArgoCD
└── architecture.drawio
```

## How it works

Three repositories, one GitOps loop:

```
terraform/  →  provisions the cluster + installs ArgoCD
app/        →  CI builds images, renders Helm charts, pushes YAML to manifests/
manifests/  →  ArgoCD polls this repo and applies changes to the cluster
```

A commit to `app/` triggers the CI pipeline. The pipeline builds Docker images, pushes them to ECR, runs `helm template` to produce plain Kubernetes YAML, and commits the result to `manifests/`. ArgoCD detects the change and syncs the cluster — no manual `kubectl apply` anywhere.

## Infrastructure overview

| Component | Technology |
|---|---|
| Cloud | AWS us-east-1 |
| Cluster | EKS (Kubernetes 1.31), managed node group |
| Networking | VPC with public + private subnets, NAT Gateway, ALB |
| Container registry | ECR — `prod/api`, `prod/ui`, `prod/lambda` |
| Database | RDS PostgreSQL (private subnet) |
| Serverless | AWS Lambda (OCI image, managed by ACK Lambda Controller) |
| Queue | SQS FIFO (triggers Lambda via EventSourceMapping) |
| Storage | S3 (PDF output files) |
| Config | SSM Parameter Store (`/prod/*`) |
| DNS / TLS | Route53 + ACM wildcard certificate |
| GitOps operator | ArgoCD |
| IaC | Terraform 1.9 + S3 backend + DynamoDB state lock |

## CI/CD platforms

| Platform | Trigger | Use case |
|---|---|---|
| GitLab CI | Auto on push to `prod` branch | Default — day-to-day deployments |
| GitHub Actions | Manual (`workflow_dispatch`) | Secondary — cross-platform validation |

Both pipelines share the same Terraform S3 state. Only one runs at a time (DynamoDB locking).

## Quick start

### Deploy infrastructure

```bash
cd terraform/
cp terraform.example.tfvars terraform.tfvars   # fill in your values
terraform init
terraform plan
terraform apply
```

Provisioning takes ~20 minutes. ArgoCD and the ingress controller are installed automatically via Helm.

### Deploy the application

Push a commit to the `prod` branch of `app/`. The CI pipeline handles the rest.

### Destroy

```bash
# Via GitLab CI: trigger the destroy job manually from the pipeline UI
# Via CLI:
cd terraform/
terraform destroy
```

> **Cost notice**: the EKS cluster (2× t3.medium nodes) accrues charges while running. Destroy when not in use.

## Application endpoints

| URL | Description |
|---|---|
| `https://demoapp.prod.<your-domain>/` | Web UI |
| `https://demoapp.prod.<your-domain>/api/version` | API version check |
| `https://argo.prod.<your-domain>/` | ArgoCD dashboard |
