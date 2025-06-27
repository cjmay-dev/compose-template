.PHONY: clean compose terraform-init terraform-plan terraform-apply

compose:
	@docker compose pull
	@docker compose build
	@docker compose up -d

terraform-apply: terraform/.terraform.lock.hcl
	@terraform -chdir=terraform apply -auto-approve

terraform-plan: terraform/.terraform.lock.hcl
	@terraform -chdir=terraform plan

terraform-init: terraform/.terraform.lock.hcl

terraform/.terraform.lock.hcl: terraform/backend.tf
	@terraform -chdir=terraform init -upgrade -migrate-state

terraform/backend.tf:
	@python3 -m venv venv
	@./venv/bin/pip install -r scripts/requirements.txt
	@./venv/bin/python scripts/generate_tfstate_backend.py

clean:
	@echo "Cleaning up..."
	@docker compose down 2> /dev/null || echo
	@rm -f terraform/backend.tf terraform/.terraform.lock.hcl terraform/errored.tfstate
	@rm -rf terraform/.terraform
	@rm -rf venv
