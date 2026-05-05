# hpc-cluster

Two-node GPU cluster managed with Ansible.

- **master** (10.172.13.40) -- Slurm controller, JupyterHub
- **worker / bserver** (10.172.13.45) -- Slurm compute node, NVIDIA GTX 1080

---

## Playbooks

| Command | What it does |
|---|---|
| `make provision` | Full setup: common packages + GPU drivers + Slurm |
| `make gpu` | Install NVIDIA driver 550 and CUDA toolkit on GPU nodes |
| `make slurm` | Install and configure slurmctld (master) and slurmd (workers) |
| `make jupyterhub` | Install JupyterHub on master, PyTorch GPU kernel on workers |
| `make ping` | Check SSH connectivity to all nodes |
| `make verify` | Run nvidia-smi on GPU nodes |
| `make test-slurm` | Submit a one-liner srun job to confirm Slurm works |
| `make syntax-check` | Validate all playbook YAML |
| `make reboot-workers` | Reboot worker nodes and wait for SSH |

---

## Adding a new worker node

**Step 1** -- add the host to `inventory.ini` under `[workers]`:

```ini
[workers]
worker-node  ansible_host=10.172.13.45  ansible_user=blagoy
new-worker   ansible_host=10.172.13.XX  ansible_user=youruser
```

If the new node has a GPU, add a `host_vars/new-worker.yml`:

```yaml
slurm_gres: "gpu:gtx1080:1"
slurm_gres_devices:
  - { name: gpu, type: gtx1080, file: /dev/nvidia0 }
```

**Step 2** -- run the playbooks:

```bash
make gpu    # installs GPU drivers on the new node
make slurm  # regenerates slurm.conf and starts slurmd
```

Slurm picks up the new node automatically -- `slurm.conf` is generated from the inventory.

---

## Submitting a Slurm job

See `jobs/test_gpu.sh` for a working example. Basic template:

```bash
#!/bin/bash
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --gres=gpu:1
#SBATCH --output=/tmp/%x-%j.out

source /etc/profile.d/cuda.sh
source /opt/jupyter-worker/bin/activate

python3 your_script.py
```

Submit and monitor:

```bash
sbatch job.sh
squeue          # watch queue
sinfo           # node state
```

Reference: https://slurm.schedmd.com/sbatch.html

---

## JupyterHub

Access at `http://10.172.13.40:8000`. Log in with your system account (PAM auth).

Each notebook server runs as a Slurm job on the compute partition -- the "Python (PyTorch GPU)" kernel has direct GPU access via CUDA 12.x.

If a node goes DOWN after a reboot, resume it on master:

```bash
sudo scontrol update nodename=bserver state=resume
```

Reference: https://jupyterhub.readthedocs.io
