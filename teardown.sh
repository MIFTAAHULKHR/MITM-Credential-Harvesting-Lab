#!/bin/bash
# ============================================================
# teardown.sh — Clean up the lab environment
# ============================================================

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   MITM Lab Teardown                    ${NC}"
echo -e "${CYAN}========================================${NC}"

echo -e "\n${YELLOW}[1/4] Stopping and removing containers...${NC}"
docker compose -f "$(dirname "$0")/../docker/docker-compose.yml" down 2>/dev/null || true
docker rm -f attacker 2>/dev/null || true
echo -e "${GREEN}    ✓ Containers removed${NC}"

echo -e "\n${YELLOW}[2/4] Removing macvlan network...${NC}"
docker network rm mitm-net 2>/dev/null || true
echo -e "${GREEN}    ✓ mitm-net removed${NC}"

echo -e "\n${YELLOW}[3/4] Removing macvlan shim interface...${NC}"
sudo ip link del macvlan-shim 2>/dev/null || true
echo -e "${GREEN}    ✓ macvlan-shim removed${NC}"

echo -e "\n${YELLOW}[4/4] Restoring iptables FORWARD default...${NC}"
sudo iptables -D FORWARD -i vboxnet0 -o vboxnet0 -j ACCEPT 2>/dev/null || true
echo -e "${GREEN}    ✓ iptables restored${NC}"

echo -e "\n${GREEN}  Lab environment cleaned up.${NC}\n"
