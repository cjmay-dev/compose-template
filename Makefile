.PHONY: clean compose terraform

compose:
	@docker compose pull
	@docker compose build
	@docker compose up -d

terraform: terraform/backend.tf terraform/.terraform.lock.hcl
	@if [ -z "$GITHUB_ACTIONS" ]; then \
		@echo "---WARNING---"; \
		@echo "This target is only meant to be run in GitHub Actions."; \
		@echo "If you know what you're doing, set GITHUB_ACTIONS=true"; \
		@echo "-------------"; \
		exit 1; \
	fi
	@terraform -chdir=terraform plan
	@terraform -chdir=terraform apply -auto-approve

terraform/backend.tf terraform/.terraform.lock.hcl:
	@python3 -m venv venv
	@./venv/bin/pip install -r scripts/requirements.txt
	./venv/bin/python scripts/generate_tfstate_backend.py
	@terraform -chdir=terraform init -upgrade

clean:
	@echo "Cleaning up..."
	@docker compose down 2> /dev/null || echo
	@rm -f terraform/backend.tf terraform/.terraform.lock.hcl terraform/errored.tfstate
	@rm -rf terraform/.terraform
	@rm -rf venv
