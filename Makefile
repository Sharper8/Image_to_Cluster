
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
	@which docker >/dev/null 2>&1 || (echo "docker is required but not found; please install Docker" && exit 1);
	@which packer >/dev/null 2>&1 || ( \
		echo "packer not found; attempting to install via HashiCorp apt repo (Ubuntu/Debian)..." && \
		if [ -f /etc/debian_version ]; then \
			sudo apt-get update && sudo apt-get install -y curl gnupg software-properties-common && \
			curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
			echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null && \
			sudo apt-get update && sudo apt-get install -y packer || echo "Failed to install packer; please install manually"; \
		else \
			echo "Non-debian OS: please install packer manually"; \
		fi ) || true;
	@which k3d >/dev/null 2>&1 || ( \
		echo "k3d not found; attempting to install via upstream script..." && \
		curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | sudo bash || echo "Failed to install k3d; please install manually" ) || true;
	@which ansible-playbook >/dev/null 2>&1 || ( \
		echo "ansible-playbook not found; will fall back to kubectl-based deploy if needed"; \
		# try user pip install as a lightweight fallback (no sudo)
		if command -v python3 >/dev/null 2>&1; then \
			python3 -m pip install --user ansible-core ansible >/dev/null 2>&1 || true; \
			if [ -d "$(python3 -m site --user-base)/bin" ]; then \
				echo "Note: user-local pip binaries installed to $(python3 -m site --user-base)/bin"; \
			fi; \
		fi ) || true;
	@which kubectl >/dev/null 2>&1 || ( \
		echo "kubectl not found; attempting to install kubectl binary..." && \
		KRELEASE=$$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
		curl -LO https://dl.k8s.io/release/$$KRELEASE/bin/linux/amd64/kubectl && \
		sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl || echo "Failed to install kubectl; please install manually"; \
		rm -f kubectl || true ) || true;

deploy:
	ansible-playbook ansible/deploy.yml

clean:
	docker rmi image_to_cluster/nginx-custom:latest || true
