
.PHONY: all packer-build import-image deploy clean

all: packer-build import-image deploy

# Try Packer if available, otherwise fallback to Docker build
packer-build:
	@echo "Attempting packer build (will fallback to docker build on failure)...";
	@packer build packer/template.json || (echo "Packer build failed — falling back to docker build" && docker build -t image_to_cluster/nginx-custom:latest .)

import-image:
	@echo "Importing image into k3d (no-op if not running k3d)";
	@k3d image import image_to_cluster/nginx-custom:latest -c lab || true

deploy:
	ansible-playbook ansible/deploy.yml

clean:
	docker rmi image_to_cluster/nginx-custom:latest || true
