INVENTORY := ansible/inventory.ini
PLAYBOOK := ansible/site.yml
VAULT_PASSWORD_FILE ?= ~/.vault_pass
ANSIBLE_EXTRA ?=

.PHONY: help playbook-vault playbook-vault-file syntax-check check lint deploy

help:
	@echo "  make deploy                # Run playbook (uses $(INVENTORY) and $(PLAYBOOK))"
	@echo "  make deploy-pass          # Run playbook and ask for vault password"
	@echo "  make playbook-vault-file     # Run playbook using VAULT_PASSWORD_FILE"
	@echo "  make syntax-check           # Run ansible syntax check"
	@echo "  make check                  # Run playbook in --check (dry-run) mode"
	@echo "  make lint                   # Run ansible-lint (if installed)"

deploy:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) $(ANSIBLE_EXTRA)

deploy-pass:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --ask-vault-pass $(ANSIBLE_EXTRA)

playbook-vault-file:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --vault-password-file $(VAULT_PASSWORD_FILE) $(ANSIBLE_EXTRA)

syntax-check:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --syntax-check

check:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --check --diff

encrypt-vault:
	ansible-vault encrypt ansible/group_vars/cloud/vault.yml --vault-password-file ~/.vault_pass
