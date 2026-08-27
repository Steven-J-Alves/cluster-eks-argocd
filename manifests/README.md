# manifests

GitOps repository. Contains the rendered Kubernetes manifests for the application. ArgoCD watches this repo and applies any change to the cluster automatically.

## How this repo is updated

This repo is never edited by hand. The CI pipeline in `app/` runs `helm template` after every successful build and commits the rendered YAML here:

```
app/ CI pipeline
  └─ helm template demoapp ...
  └─ git push → manifests/ (prod branch)
       └─ ArgoCD detects diff
            └─ kubectl apply → EKS cluster
```

**GitLab CI** pushes directly to the GitLab remote.  
**GitHub Actions** pushes to the GitHub mirror via the `cpina/push-to-another-repository` action.

ArgoCD watches one source at a time, toggled by the `MODE` variable in the `terraform/` pipeline.

## Directory layout

```
manifests/
└── demoapp/
    └── demoapp/
        └── charts/
            ├── api/templates/
            │   ├── deployment.yaml   # Go API — ECR image prod/api:<sha8>
            │   └── service.yaml      # ClusterIP → port 8080
            ├── ui/templates/
            │   ├── deployment.yaml   # React UI — ECR image prod/ui:<sha8>
            │   └── service.yaml      # ClusterIP → port 80
            ├── ingress/templates/
            │   └── ingress.yaml      # nginx IngressClass, host routing
            └── lambda/templates/
                ├── function.yaml              # ACK Function CRD (OCI image)
                └── eventsourcemapping.yaml    # ACK EventSourceMapping (SQS → Lambda)
```

## Kubernetes namespaces

| Namespace | Contents |
|---|---|
| `application` | API deployment, UI deployment, Ingress |
| `ack-lambda` | ACK Lambda Controller (manages Function + EventSourceMapping CRDs) |
| `argocd` | ArgoCD server |

## ACK Lambda CRDs

Lambda is not deployed via a standard Kubernetes workload — it runs as an AWS-managed function outside the cluster. To keep it inside the GitOps loop, the ACK Lambda Controller translates Kubernetes custom resources (`Function`, `EventSourceMapping`) into AWS API calls.

This means updating the Lambda image is as simple as committing a new `function.yaml` with an updated `imageURI`. No separate Lambda deployment pipeline needed.

## Branch

All manifests live on the `prod` branch. ArgoCD is configured to track this branch with auto-sync, pruning, and self-heal enabled.

> **Security note**: this repo contains rendered manifests including image URIs and environment configuration. Keep it private in production.
