# ----------------------------
# Global Environment for developer experience to make them not type wrong commands
# ----------------------------
# Default environment is dev, override with `just env=prod <command>`
env := "dev"
# Dynamically set the docker compose command based on the environment
compose := if env == "dev" { "docker compose -f compose.dev.yml" } else { "docker compose -f compose.yml" }
export GIT_SHA := `git rev-parse --short HEAD 2>/dev/null || echo "unknown"`
export VERSION := `git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0"`
# Default manifest directory
manifests := "k8s/"
# List all available commands
default:
    @just --list

# ----------------------------
# Workflows (Adapts to dev or prod automatically)
# ----------------------------
# Start all services in the background
up:
    {{compose}} up -d
# Build fresh and start all services in the background
up-build:
    {{compose}} up --build -d
# Stop and remove containers, networks, etc.
down:
    {{compose}} down
# Stop a specific service or all if none given (keeps container intact)
stop service="":
    {{compose}} stop {{service}}
# Build all images fresh, NO cache
build:
    {{compose}} build --no-cache
# Build all images FAST, USING cache
build-fast:
    {{compose}} build
# Down + up in one shot
restart: down up
# Follow logs for all services
logs:
    {{compose}} logs -f
# Show all containers
ps:
    {{compose}} ps --format "table {{ '{{.Name}}' }}\t{{ '{{.Service}}' }}\t{{ '{{.Status}}' }}\t{{ '{{.Ports}}' }}"
# Show ONLY running containers
ps-running:
    {{compose}} ps --status=running --format "table {{ '{{.Name}}' }}\t{{ '{{.Service}}' }}\t{{ '{{.Status}}' }}\t{{ '{{.Ports}}' }}"
# Full clean: Stop containers, remove images, volumes, and orphans
clean:
    {{compose}} down --rmi all --volumes --remove-orphans

# ----------------------------
# Cleanup
# ----------------------------
# Full Docker system prune - removes everything unused
prune:
    docker system prune -af --volumes

# ----------------------------
# Info & Diagnostics
# ----------------------------
# Inspect OCI labels on all images
labels:
    #!/usr/bin/env bash
    for img in my-app-backend:latest my-app-frontend:latest; do
        echo "=== $img ==="
        docker inspect $img --format '{{ '{{ json .Config.Labels }}' }}' | jq
    done
# Print current environment and git metadata
info:
    @echo "ENVIRONMENT = {{env}}"
    @echo "COMPOSE CMD = {{compose}}"
    @echo "GIT_SHA     = {{GIT_SHA}}"
    @echo "VERSION     = {{VERSION}}"

# ----------------------------
# Kubernetes
# ----------------------------
# Validate a single manifest: just k-validate f=1-deployment.yaml
k-validate f:
    @echo "→ Linting {{f}}..."
    yamllint "{{f}}"
    @echo "→ Validating against Kubernetes schemas..."
    kubeconform "{{f}}"
    @echo "→ Dry-run against cluster..."
    kubectl apply --dry-run=client -f "{{f}}"
    @echo "✅ {{f}} passed all checks"

# Validate all manifests in the k8s/ directory at once
k-validate-all:
    @echo "→ Linting all manifests..."
    yamllint {{manifests}}
    @echo "→ Validating against Kubernetes schemas..."
    kubeconform {{manifests}}
    @echo "→ Dry-run against cluster..."
    kubectl apply --dry-run=client -f {{manifests}}
    @echo "✅ All manifests passed"

# Apply a single manifest: just k-apply f=1-deployment.yaml
k-apply f: (k-validate f)
    kubectl apply -f "{{f}}"

# Apply all manifests in the k8s/ directory
k-apply-all: k-validate-all
    kubectl apply -f {{manifests}}

# Delete a single manifest from the cluster
k-delete f:
    kubectl delete -f "{{f}}"

# Show status of all resources
k-status:
    @echo "=== Nodes ==="
    kubectl get nodes
    @echo "=== Pods ==="
    kubectl get pods -o wide
    @echo "=== Services ==="
    kubectl get svc
    @echo "=== PVCs ==="
    kubectl get pvc
    @echo "=== PVs ==="
    kubectl get pv

# Stream logs for a deployment: just k-logs app=real-web-app
k-logs app:
    kubectl logs -l app={{app}} -f

# Describe a pod for debugging: just k-describe pod=<pod-name>
k-describe pod:
    kubectl describe pod {{pod}}
