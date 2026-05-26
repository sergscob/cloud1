VENV_DIR ?= .venv
PYTHON ?= python3
PIP := $(VENV_DIR)/bin/pip
ANSIBLE_PLAYBOOK := $(VENV_DIR)/bin/ansible-playbook
ANSIBLE_VAULT := $(VENV_DIR)/bin/ansible-vault
INVENTORY := ansible/inventory.ini
PLAYBOOK := ansible/site.yml
#VAULT_PASSWORD_FILE ?= ~/.vault_pass

.PHONY: venv syntax-check check encrypt-vault all all-pass task

venv:
	@if [ ! -x "$(ANSIBLE_PLAYBOOK)" ]; then \
		$(PYTHON) -m venv "$(VENV_DIR)"; \
		"$(PIP)" install --upgrade pip; \
		"$(PIP)" install -r requirements.txt; \
	fi

all: venv
	"$(ANSIBLE_PLAYBOOK)" -i $(INVENTORY) $(PLAYBOOK) --ask-vault-pass -u root --ask-pass
# 	"$(ANSIBLE_PLAYBOOK)" -i $(INVENTORY) $(PLAYBOOK) --vault-password-file $(VAULT_PASSWORD_FILE)

all-pass: venv
	"$(ANSIBLE_PLAYBOOK)" -i $(INVENTORY) $(PLAYBOOK) --ask-vault-pass

task: venv
	@if [ -z "$(TAG)" ]; then \
		echo "Usage: make task TAG=<tag>"; \
		exit 1; \
	fi
	"$(ANSIBLE_PLAYBOOK)" -i $(INVENTORY) $(PLAYBOOK) --tags "$(TAG)" --ask-vault-pass 
# 	"$(ANSIBLE_PLAYBOOK)" -i $(INVENTORY) $(PLAYBOOK) --tags "$(TAG)" --vault-password-file $(VAULT_PASSWORD_FILE)

syntax-check: venv
	"$(ANSIBLE_PLAYBOOK)" -i $(INVENTORY) $(PLAYBOOK) --syntax-check --ask-vault-pass
# 	"$(ANSIBLE_PLAYBOOK)" -i $(INVENTORY) $(PLAYBOOK) --syntax-check --vault-password-file $(VAULT_PASSWORD_FILE)

check: venv
	"$(ANSIBLE_PLAYBOOK)" -i $(INVENTORY) $(PLAYBOOK) --check --diff --ask-vault-pass
# 	"$(ANSIBLE_PLAYBOOK)" -i $(INVENTORY) $(PLAYBOOK) --check --diff --vault-password-file $(VAULT_PASSWORD_FILE)

encrypt-vault:
	"$(ANSIBLE_VAULT)" encrypt ansible/group_vars/cloud/vault.yml --vault-password-file ~/.vault_pass

