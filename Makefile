export PATH := $(HOME)/.local/bin:$(PATH)

INVENTORY      := inventory.ini
PLAYBOOK       := ansible-playbook -i $(INVENTORY)
PLAYBOOK_PRIV  := ansible-playbook -i $(INVENTORY) --ask-become-pass
ANSIBLE_PRIV   := ansible -i $(INVENTORY) --ask-become-pass

.DEFAULT_GOAL := help

.PHONY: help install ping syntax-check deploy common gpu verify reboot-master

help:
	@echo "Targets:"
	@echo "  install        pip install -r requirements.txt --user"
	@echo "  ping           connectivity check (all nodes)"
	@echo "  syntax-check   validate all playbooks"
	@echo "  deploy         run site.yml (common + gpu)"
	@echo "  common         run common setup only (all nodes)"
	@echo "  gpu            run CUDA/driver install (gpu_nodes)"
	@echo "  verify         run nvidia-smi check after reboot"
	@echo "  reboot-master  reboot master and wait for SSH"

install:
	python3 -m pip install -r requirements.txt --user --break-system-packages

ping:
	$(PLAYBOOK) ping.yml

syntax-check:
	$(PLAYBOOK) site.yml --syntax-check

deploy:
	$(PLAYBOOK_PRIV) site.yml

common:
	$(PLAYBOOK_PRIV) playbooks/common.yml

gpu:
	$(PLAYBOOK_PRIV) playbooks/gpu.yml

verify:
	$(PLAYBOOK_PRIV) playbooks/gpu.yml --tags verify

reboot-master:
	$(ANSIBLE_PRIV) master -m reboot --become
