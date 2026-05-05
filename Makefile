export PATH := $(HOME)/.local/bin:$(PATH)

INVENTORY     := inventory.ini
PLAYBOOK      := ansible-playbook -i $(INVENTORY)
PLAYBOOK_PRIV := ansible-playbook -i $(INVENTORY) --ask-become-pass
ANSIBLE       := ansible -i $(INVENTORY)
ANSIBLE_PRIV  := ansible -i $(INVENTORY) --ask-become-pass

.DEFAULT_GOAL := help

.PHONY: help install provision gpu slurm jupyterhub fix-uids ping verify test-slurm syntax-check reboot-master reboot-workers

help:
	@echo ""
	@echo "  Bootstrap"
	@echo "    install          pip install -r requirements.txt --user"
	@echo ""
	@echo "  Provision"
	@echo "    provision        full cluster setup (common + gpu + slurm)"
	@echo "    gpu              CUDA/driver install on gpu_nodes"
	@echo "    slurm            Slurm install/config on all nodes"
	@echo "    jupyterhub       JupyterHub + PyTorch GPU kernel"
	@echo "    fix-uids         align worker UIDs to match master (no active sessions on worker)"
	@echo ""
	@echo "  Verify"
	@echo "    ping             SSH connectivity check (all nodes)"
	@echo "    syntax-check     validate all playbooks"
	@echo "    verify           nvidia-smi check on gpu_nodes"
	@echo "    test-slurm       submit srun hostname job"
	@echo ""
	@echo "  Ops"
	@echo "    reboot-master    reboot master and wait for SSH"
	@echo "    reboot-workers   reboot all workers and wait for SSH"
	@echo ""

# ── Bootstrap ────────────────────────────────────────────────────────────────
install:
	python3 -m pip install -r requirements.txt --user --break-system-packages

# ── Provision ────────────────────────────────────────────────────────────────
provision:
	$(PLAYBOOK_PRIV) site.yml

gpu:
	$(PLAYBOOK_PRIV) playbooks/gpu.yml

slurm:
	$(PLAYBOOK_PRIV) playbooks/slurm.yml

jupyterhub:
	$(PLAYBOOK_PRIV) playbooks/jupyterhub.yml

fix-uids:
	$(PLAYBOOK_PRIV) playbooks/fix_uids.yml

# ── Verify ───────────────────────────────────────────────────────────────────
ping:
	$(PLAYBOOK) ping.yml

syntax-check:
	$(PLAYBOOK) site.yml --syntax-check

verify:
	$(PLAYBOOK_PRIV) playbooks/gpu.yml --tags verify

test-slurm:
	$(ANSIBLE) master -m command -a "srun --partition=compute --nodes=1 hostname"

# ── Ops ──────────────────────────────────────────────────────────────────────
reboot-master:
	$(ANSIBLE_PRIV) master -m reboot --become

reboot-workers:
	$(ANSIBLE_PRIV) workers -m reboot --become
