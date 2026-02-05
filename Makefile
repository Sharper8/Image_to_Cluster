
.PHONY: all deps packer-build import-image deploy clean

all: deps packer-build import-image deploy

# Try Packer if available, otherwise fallback to Docker build
packer-build:
	@echo "Attempting packer build (will fallback to docker build on failure)...";
	@packer build packer/template.json || (echo "Packer build failed — falling back to docker build" && docker build -t image_to_cluster/nginx-custom:latest .)

import-image:
	@echo "Importing image into k3d (no-op if not running k3d)";
	@# create cluster 'lab' if it does not exist
	@k3d cluster list | grep -q "\blab\b" || (echo "k3d cluster 'lab' not found — creating..." && k3d cluster create lab --servers 1 --agents 2)
	@k3d image import image_to_cluster/nginx-custom:latest -c lab || true


deps:
	@echo "Checking required tools: packer k3d ansible kubectl docker";
	@bash -lc '\
set -euo pipefail; \
which docker >/dev/null 2>&1 || { echo "docker is required but not found; please install Docker"; exit 1; }; \
if ! command -v packer >/dev/null 2>&1; then \
  echo "packer not found; attempting to download packer binary..."; \
  if command -v curl >/dev/null 2>&1; then \
    VER=$$(curl -s https://checkpoint-api.hashicorp.com/v1/check/packer | sed -n "s/.*\"current_version\":\"\([^\"]*\)\".*/\1/p"); \
    if [ -n "$$VER" ]; then \
      URL="https://releases.hashicorp.com/packer/$${VER}/packer_$${VER}_linux_amd64.zip"; \
      echo "Downloading $$URL"; \
      curl -sSLo /tmp/packer.zip "$$URL" || true; \
      if [ -s /tmp/packer.zip ]; then \
        if command -v unzip >/dev/null 2>&1; then \
          unzip -o /tmp/packer.zip -d /tmp >/dev/null 2>&1 || true; \
        elif command -v python3 >/dev/null 2>&1; then \
          python3 -c "import zipfile; zipfile.ZipFile('/tmp/packer.zip').extractall('/tmp')" || true; \
        else \
          echo "unzip or python3 required to extract packer"; \
        fi; \
        if [ -f /tmp/packer ]; then \
          sudo install -m 0755 /tmp/packer /usr/local/bin/packer || true; \
        else \
          echo "Failed to extract packer binary"; \
        fi; \
        rm -f /tmp/packer /tmp/packer.zip || true; \
      else \
        echo "Failed to download packer archive"; \
      fi; \
    else \
      echo "Could not determine packer version; please install packer manually"; \
    fi; \
  else \
    echo "curl required to auto-install packer; please install packer manually"; \
  fi; \
fi; \
if ! command -v k3d >/dev/null 2>&1; then \
  echo "k3d not found; installing via upstream script..."; \
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | sudo bash || echo "Failed to install k3d"; \
fi; \
if ! command -v ansible-playbook >/dev/null 2>&1; then \
  echo "ansible-playbook not found; attempting user pip install of ansible-core"; \
  if command -v python3 >/dev/null 2>&1; then \
    python3 -m pip install --user ansible-core ansible || echo "pip install ansible failed"; \
  else \
    echo "python3 not available; please install ansible manually"; \
  fi; \
fi; \
if ! command -v kubectl >/dev/null 2>&1; then \
  echo "kubectl not found; installing kubectl binary..."; \
  KRELEASE=$$(curl -L -s https://dl.k8s.io/release/stable.txt); \
  curl -Lo /tmp/kubectl https://dl.k8s.io/release/$$KRELEASE/bin/linux/amd64/kubectl && sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl || echo "Failed to install kubectl"; \
  rm -f /tmp/kubectl || true; \
fi; \
echo "deps check complete"; '

deploy:
	@if command -v ansible-playbook >/dev/null 2>&1; then \
		ansible-playbook ansible/deploy.yml; \
	elif command -v python3 >/dev/null 2>&1; then \
		python3 -m ansible.cli.playbook ansible/deploy.yml || \
		( echo "ansible not available; falling back to kubectl" && \
		kubectl apply -f k8s/deployment.yaml && \
		kubectl rollout restart deployment/nginx-custom && \
		kubectl rollout status deployment/nginx-custom --timeout=120s && \
		kubectl get pods -l app=nginx-custom -o wide ); \
	else \
		echo "ansible not available; falling back to kubectl"; \
		kubectl apply -f k8s/deployment.yaml && \
		kubectl rollout restart deployment/nginx-custom && \
		kubectl rollout status deployment/nginx-custom --timeout=120s && \
		kubectl get pods -l app=nginx-custom -o wide; \
	fi

clean:
	docker rmi image_to_cluster/nginx-custom:latest || true
