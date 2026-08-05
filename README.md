# Syook Encryption Application — GitOps

GitOps repository for deploying the Syook Encryption Application stack to a single EC2 instance via Docker Compose. Application source lives in separate service repositories; this repo owns **infrastructure (Terraform)** and **deployment (Docker Compose + GitHub Actions CD)** only.

## Architecture

The stack is composed of the following services, orchestrated by [docker-compose.prod.yml](docker-compose.prod.yml):

| Service | Image | Port | Description |
|---|---|---|---|
| `emitter-service` | `prashantdocker090798/emitter-service` | 3000 | Publishes/emits events into the pipeline |
| `listener-service` | `prashantdocker090798/listener-service` | 4000 | Consumes emitted events, persists to MongoDB |
| `dashboard-backend` | `prashantdocker090798/dashboard-backend` | 5000 | API backend for the dashboard |
| `dashboard-frontend` | `prashantdocker090798/dashboard-frontend` | 5173 (→80) | Web dashboard UI |
| `redis` | `redis:latest` | 6379 | Cache / message broker |
| `mongodb` | `mongo:7` | 27017 | Primary datastore, running as a single-node replica set (`rs0`) |
| `mongo-init` | `mongo:7` | — | One-shot job that initializes the MongoDB replica set on first boot |

All services communicate over the `encryption-app-network` bridge network. Persistent data is stored in the `redis_data` and `mongo_data` named volumes.

## Repository Structure

```
.
├── docker-compose.prod.yml   # Production stack definition (pulled & run on the EC2 host)
├── infra/                    # Terraform for the EC2 host + supporting AWS resources
│   ├── main.tf                # Key pair, security group, EC2 instance, Elastic IP
│   ├── variables.tf           # Configurable inputs (region, instance type, AMI, keys, etc.)
│   └── outputs.tf             # Instance ID, public IP/DNS, Elastic IP, ready-to-use SSH command
└── .github/workflows/
    └── build.yml               # CD pipeline: deploys docker-compose.prod.yml to EC2 on push
```

## Infrastructure (Terraform)

[infra/main.tf](infra/main.tf) provisions:

- An **EC2 key pair** from a local public key
- A **security group** allowing SSH (22), dashboard frontend (5173), and dashboard backend (5000)
- An **EC2 instance** (default: `t2.micro`, Ubuntu 22.04) whose user-data script installs Docker Engine + Compose plugin on first boot
- An **Elastic IP** attached to the instance, so the public address is stable across restarts

### Usage

```bash
cd infra
terraform init
terraform plan
terraform apply
```

Key variables (see [infra/variables.tf](infra/variables.tf) for the full list and defaults):

| Variable | Description | Default |
|---|---|---|
| `region` | AWS region | `ap-south-1` |
| `ami_id` | Ubuntu AMI | `ami-0f58b397bc5c1f2e8` (Ubuntu 22.04, ap-south-1) |
| `instance_type` | EC2 instance size | `t2.micro` |
| `public_key_path` | Local SSH public key to import | `~/.ssh/syook_encryption_app_key.pub` |
| `allowed_ssh_cidr` | CIDR allowed to SSH in | `0.0.0.0/0` (tighten this for real use) |

After apply, `terraform output ssh_command` prints a ready-to-use SSH command using the Elastic IP.

> **Note:** `infra/terraform.tfstate*` is checked into this repo. Treat it as sensitive — it can contain resource IDs and configuration details.

## Continuous Deployment

[.github/workflows/build.yml](.github/workflows/build.yml) runs on every push to `master` that touches `docker-compose.prod.yml`:

1. Checks out this repo
2. SSHes into the EC2 host (Elastic IP) using a deploy key from GitHub Secrets
3. Clones/pulls this repo on the host into `/home/ubuntu/syook-encryption-gitops`
4. Logs into Docker Hub and runs:
   ```bash
   docker compose -f docker-compose.prod.yml pull
   docker compose -f docker-compose.prod.yml up -d --remove-orphans
   docker image prune -f
   ```
5. Verifies the deployment with `docker compose ps`

### Required GitHub Secrets

| Secret | Purpose |
|---|---|
| `EC2_SSH_PRIVATE_KEY` | Private key matching the EC2 key pair, used to SSH into the host |
| `DOCKERHUB_USERNAME` | Docker Hub login for pulling service images |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `GITOPS_PAT` | GitHub PAT the EC2 host uses to clone/pull this repo |

### Deployment flow

1. A service repo builds and pushes a new image tag to Docker Hub.
2. This repo's `docker-compose.prod.yml` is updated with the new image tag (typically by an automated commit from the CI of the service repo).
3. The push to `master` triggers the CD workflow above, which pulls and redeploys the stack on the EC2 host.

## Manual Deployment

To deploy or update the stack manually on the host:

```bash
ssh -i ~/.ssh/syook_encryption_app_key ubuntu@<elastic-ip>
cd /home/ubuntu/syook-encryption-gitops
git pull origin master
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d --remove-orphans
```

## License

See [LICENSE](LICENSE).
