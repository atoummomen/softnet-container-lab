#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Deploy inter-subnet-gateway-lab ContainerLab Topology ==="

cd "${SCRIPT_DIR}"

echo ""
echo "== Step 1: Check/build Docker image =="
if ! docker images clab-ubuntu-softnet:latest --format '{{.Repository}}:{{.Tag}}' | grep -q "clab-ubuntu-softnet:latest"; then
    echo "[INFO] Building Docker image..."
    docker build -t clab-ubuntu-softnet:latest .
    echo "[OK] Docker image built"
else
    echo "[OK] Docker image already exists"
fi

echo ""
echo "== Step 2: Deploy containerlab topology =="
if containerlab inspect -t inter-subnet-gateway-lab.clab.yml >/dev/null 2>&1; then
    echo "[WARN] Topology already exists, destroying first..."
    containerlab destroy -t inter-subnet-gateway-lab.clab.yml --cleanup
fi

containerlab deploy -t inter-subnet-gateway-lab.clab.yml
echo "[OK] Topology deployed"

echo ""
echo "== Step 3: Verify deployment =="
containerlab inspect -t inter-subnet-gateway-lab.clab.yml

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Access nodes:"
echo "  docker exec -it clab-inter-subnet-gateway-lab-hs1 bash"
echo "  docker exec -it clab-inter-subnet-gateway-lab-rt1 bash"
echo "  docker exec -it clab-inter-subnet-gateway-lab-hs2 bash"
echo ""
echo "Test connectivity:"
echo "  docker exec clab-inter-subnet-gateway-lab-hs1 ping -c 3 10.0.2.2"
echo "  docker exec clab-inter-subnet-gateway-lab-hs2 ping -c 3 10.0.1.2"
echo "  docker exec clab-inter-subnet-gateway-lab-hs1 ping -6 -c 3 fc00:2::2"
echo "  docker exec clab-inter-subnet-gateway-lab-hs2 ping -6 -c 3 fc00:1::2"
echo ""
echo "Destroy: cd containerlab && ./destroy.sh"
