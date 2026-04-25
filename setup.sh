#!/bin/bash
# ============================================================
# setup.sh — One-command lab setup
# Run this on Kali Linux host before starting the lab
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   MITM Lab Setup Script                ${NC}"
echo -e "${CYAN}========================================${NC}"

# --- Step 1: Enable IP forwarding ---
echo -e "\n${YELLOW}[1/5] Enabling IP forwarding...${NC}"
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -P FORWARD ACCEPT
sudo iptables -I FORWARD -i vboxnet0 -o vboxnet0 -j ACCEPT
echo -e "${GREEN}    ✓ IP forwarding enabled${NC}"

# --- Step 2: Check vboxnet0 ---
echo -e "\n${YELLOW}[2/5] Checking vboxnet0 interface...${NC}"
if ip link show vboxnet0 &>/dev/null; then
    IP=$(ip addr show vboxnet0 | grep 'inet ' | awk '{print $2}')
    echo -e "${GREEN}    ✓ vboxnet0 found — $IP${NC}"
else
    echo -e "${RED}    ✗ vboxnet0 not found. Create it in VirtualBox: File > Host Network Manager${NC}"
    exit 1
fi

# --- Step 3: Create macvlan network ---
echo -e "\n${YELLOW}[3/5] Creating Docker macvlan network...${NC}"
if docker network inspect mitm-net &>/dev/null; then
    echo -e "${GREEN}    ✓ mitm-net already exists${NC}"
else
    docker network create \
        --driver macvlan \
        --subnet=192.168.56.0/24 \
        --gateway=192.168.56.1 \
        --opt parent=vboxnet0 \
        mitm-net
    echo -e "${GREEN}    ✓ mitm-net created${NC}"
fi

# --- Step 4: Start target containers ---
echo -e "\n${YELLOW}[4/5] Starting target containers...${NC}"
docker compose -f "$(dirname "$0")/../docker/docker-compose.yml" up -d
echo -e "${GREEN}    ✓ Containers started${NC}"

# --- Step 5: Create macvlan shim (host ↔ container access) ---
echo -e "\n${YELLOW}[5/5] Creating macvlan host shim (192.168.56.5)...${NC}"
if ip link show macvlan-shim &>/dev/null; then
    echo -e "${GREEN}    ✓ macvlan-shim already exists${NC}"
else
    sudo ip link add macvlan-shim link vboxnet0 type macvlan mode bridge
    sudo ip addr add 192.168.56.5/24 dev macvlan-shim
    sudo ip link set macvlan-shim up
    echo -e "${GREEN}    ✓ macvlan-shim created at 192.168.56.5${NC}"
fi

# --- Summary ---
echo -e "\n${CYAN}========================================${NC}"
echo -e "${GREEN}  Lab is ready!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "  Targets:"
echo -e "    DVWA       → http://192.168.56.20  (run setup.php first)"
echo -e "    WebGoat    → http://192.168.56.21/WebGoat"
echo -e "    Juice Shop → http://192.168.56.22"
echo ""
echo -e "  Start attacker container:"
echo -e "    docker run -it --name attacker --network mitm-net --ip 192.168.56.10 \\"
echo -e "      --cap-add NET_ADMIN --cap-add NET_RAW \\"
echo -e "      bettercap/bettercap -iface eth0 -caplet /root/bettercap.caplet"
echo ""
