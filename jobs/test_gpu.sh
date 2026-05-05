#!/bin/bash
#SBATCH --job-name=test-gpu
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --gres=gpu:1
#SBATCH --output=/tmp/test-gpu-%j.out
#SBATCH --error=/tmp/test-gpu-%j.err

source /etc/profile.d/cuda.sh
source /opt/jupyter-worker/bin/activate

python3 - << 'PYEOF'
import torch

print("CUDA available:", torch.cuda.is_available())
print("Device count: ", torch.cuda.device_count())
print("Device name:  ", torch.cuda.get_device_name(0))

x = torch.randn(4096, 4096, device="cuda")
y = torch.randn(4096, 4096, device="cuda")
z = torch.mm(x, y)
torch.cuda.synchronize()

print("Matrix multiply shape:", z.shape)
print("TEST PASSED")
PYEOF
