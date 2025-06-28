.PHONY: clean compose configure terraform-init terraform-plan terraform-apply terraform-destroy

compose:
	@docker compose pull
	@docker compose build
	@docker compose up -d

configure: ansible/inventory.yml
	@ansible-playbook -i ansible/inventory.yml ansible/docker-host-setup.yml

ansible/inventory.yml:
	@echo "${APP_SHORTNAME}.${LOCAL_DOMAIN}" > ansible/inventory.yml

terraform-destroy: terraform/.terraform.lock.hcl
	@terraform -chdir=terraform destroy \
	-target=module.infisical_project \
	-target=module.cloudflare_tunnel \
	-target=module.b2_bucket.b2_application_key.backups_key \
	-auto-approve
	@terraform -chdir=terraform state rm 'module.b2_bucket.b2_bucket.backups' > /dev/null 2>&1 || echo
	@terraform -chdir=terraform state rm 'module.proxmox_vm' > /dev/null 2>&1 || echo
	@echo ""
	@echo "The following resources have been removed from the state and must be cleaned up manually:"
	@echo "  - Backups B2 bucket"
	@echo "  - Proxmox VM"

terraform-apply: terraform/plan.out
	@terraform -chdir=terraform apply -auto-approve plan.out
	@rm -f terraform/plan.out

terraform-plan terraform/plan.out: terraform/.terraform.lock.hcl
	@terraform -chdir=terraform plan -out=plan.out

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
