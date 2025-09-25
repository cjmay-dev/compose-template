.PHONY: clean compose configure deploy update lock tf-init tf-plan tf-apply tf-destroy

compose:
	@docker compose pull
	@docker compose build
	@docker compose up -d

update: ansible/inventory.ini ansible_ssh_private_key
	@ansible-playbook --private-key ansible_ssh_private_key -i ansible/inventory.ini ansible/update-docker-host.yml
	@rm -f ansible_ssh_private_key

deploy: ansible/inventory.ini ansible_ssh_private_key
	@ansible-playbook --private-key ansible_ssh_private_key -i ansible/inventory.ini ansible/deploy-compose-project.yml
	@rm -f ansible_ssh_private_key

configure: ansible/inventory.ini ansible_ssh_private_key
	@ansible-playbook --private-key ansible_ssh_private_key -i ansible/inventory.ini ansible/docker-host-setup.yml
	@rm -f ansible_ssh_private_key

ansible_ssh_private_key:
	@printf '%s\n' "$$ANSIBLE_SSH_PRIVATE_KEY" > ansible_ssh_private_key
	@chmod 600 ansible_ssh_private_key

ansible/inventory.ini:
	@cp ansible/inventory.ini.template ansible/inventory.ini
	@echo "$${APP_SHORTNAME}.$${LOCAL_DOMAIN} ansible_user=ansible" >> ansible/inventory.ini

tf-destroy: terraform/.terraform.lock.hcl
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

tf-apply: terraform/plan.out
	@terraform -chdir=terraform apply -auto-approve plan.out || rm -f terraform/plan.out
	@rm -f terraform/plan.out

tf-plan terraform/plan.out: terraform/.terraform.lock.hcl
	@terraform -chdir=terraform plan -out=plan.out

tf-init terraform/.terraform.lock.hcl: terraform/backend.tf
	@terraform -chdir=terraform init -upgrade -migrate-state

terraform/backend.tf:
	@python3 -m venv venv
	@./venv/bin/pip install -r scripts/requirements.txt
	@./venv/bin/python scripts/generate_tfstate_backend.py

lock:
	@echo "Removing access to secrets..."
	@rm -f .env*
	@rm -f .infisical*
	@infisical reset

clean:
	@echo "Cleaning up..."
	@docker compose down 2> /dev/null || echo
	@rm -f ansible/inventory.yml
	@rm -f terraform/backend.tf terraform/.terraform.lock.hcl terraform/providers_override.tf terraform/errored.tfstate terraform/plan.out
	@rm -rf terraform/.terraform
	@rm -rf venv