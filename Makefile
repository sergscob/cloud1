INVENTORY := ansible/inventory.ini
PLAYBOOK := ansible/site.yml
VAULT_PASSWORD_FILE ?= ~/.vault_pass

.PHONY: syntax-check check encrypt-vault deploy deploy-pass task

deploy:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --vault-password-file $(VAULT_PASSWORD_FILE) 

deploy-pass:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --ask-vault-pass 

task:
	@if [ -z "$(TAG)" ]; then \
		echo "Usage: make task TAG=<tag>"; \
		exit 1; \
	fi
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --tags "$(TAG)" --vault-password-file $(VAULT_PASSWORD_FILE)

syntax-check:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --syntax-check --vault-password-file $(VAULT_PASSWORD_FILE)

check:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --check --diff --vault-password-file $(VAULT_PASSWORD_FILE)

encrypt-vault:
	ansible-vault encrypt ansible/group_vars/cloud/vault.yml --vault-password-file ~/.vault_pass

