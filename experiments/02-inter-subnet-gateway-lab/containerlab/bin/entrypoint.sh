#!/bin/bash
set -euo pipefail

HOSTNAME=$(hostname)
CFG_DIR="/etc/nodes"
CFG_FILE="${CFG_DIR}/${HOSTNAME}.cfg"

echo "=== Node entrypoint: ${HOSTNAME} ==="

if [[ ! -f "${CFG_FILE}" ]]; then
    echo "[FATAL] Configuration file missing: ${CFG_FILE}"
    exit 1
fi

echo "[INFO] Loading config: ${CFG_FILE}"
source "${CFG_FILE}"

ip link set lo up
echo "[OK] Loopback interface up"

configure_host() {
    echo "[INFO] Configuring host: ${HOSTNAME}"

    ip link set "${INTERFACE}" up
    echo "[OK] ${INTERFACE} interface up"

    ip addr flush dev "${INTERFACE}" 2>/dev/null || true

    ip addr add "${NODE_IP}/${NODE_PREFIX}" dev "${INTERFACE}"
    echo "[OK] IPv4 configured: ${NODE_IP}/${NODE_PREFIX}"

    ip -6 addr add "${NODE_IP6}/${NODE_PREFIX6}" dev "${INTERFACE}" nodad
    echo "[OK] IPv6 configured: ${NODE_IP6}/${NODE_PREFIX6}"

    ip route replace default via "${GATEWAY_IP}" dev "${INTERFACE}"
    echo "[OK] IPv4 default route configured via ${GATEWAY_IP}"

    ip -6 route replace default via "${GATEWAY_IP6}" dev "${INTERFACE}"
    echo "[OK] IPv6 default route configured via ${GATEWAY_IP6}"

    echo ""
    echo "[INFO] IPv4 routing table:"
    ip route

    echo ""
    echo "[INFO] IPv6 routing table:"
    ip -6 route

    echo ""
    if ping -c 2 -W 2 "${PEER_IP}" >/dev/null 2>&1; then
        echo "[OK] Peer IPv4 (${PEER_IP}) reachable"
    else
        echo "[WARN] Peer IPv4 (${PEER_IP}) not reachable"
    fi

    if ping -6 -c 2 -W 2 "${PEER_IP6}" >/dev/null 2>&1; then
        echo "[OK] Peer IPv6 (${PEER_IP6}) reachable"
    else
        echo "[WARN] Peer IPv6 (${PEER_IP6}) not reachable"
    fi
}

configure_router() {
    echo "[INFO] Configuring router: ${HOSTNAME}"

    ip link set "${LEFT_INTERFACE}" up
    ip link set "${RIGHT_INTERFACE}" up
    echo "[OK] Router interfaces up: ${LEFT_INTERFACE}, ${RIGHT_INTERFACE}"

    ip addr flush dev "${LEFT_INTERFACE}" 2>/dev/null || true
    ip addr flush dev "${RIGHT_INTERFACE}" 2>/dev/null || true

    ip addr add "${LEFT_IP}/${LEFT_PREFIX}" dev "${LEFT_INTERFACE}"
    ip addr add "${RIGHT_IP}/${RIGHT_PREFIX}" dev "${RIGHT_INTERFACE}"
    echo "[OK] IPv4 router addresses configured"

    ip -6 addr add "${LEFT_IP6}/${LEFT_PREFIX6}" dev "${LEFT_INTERFACE}" nodad
    ip -6 addr add "${RIGHT_IP6}/${RIGHT_PREFIX6}" dev "${RIGHT_INTERFACE}" nodad
    echo "[OK] IPv6 router addresses configured"

    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
    echo "[OK] IPv4 forwarding enabled"
    echo "[OK] IPv6 forwarding enabled"

    ping -6 -c 1 -W 2 "${LEFT_PEER_IP6}" >/dev/null 2>&1 || true
    ping -6 -c 1 -W 2 "${RIGHT_PEER_IP6}" >/dev/null 2>&1 || true
    echo "[OK] IPv6 neighbor discovery warmed up"

    echo ""
    echo "[INFO] IPv4 routing table:"
    ip route

    echo ""
    echo "[INFO] IPv6 routing table:"
    ip -6 route

    echo ""
    echo "[INFO] Forwarding status:"
    echo "IPv4 forwarding: $(cat /proc/sys/net/ipv4/ip_forward)"
    echo "IPv6 forwarding: $(cat /proc/sys/net/ipv6/conf/all/forwarding)"
}

case "${ROLE}" in
    host)
        configure_host
        ;;
    router)
        configure_router
        ;;
    *)
        echo "[FATAL] Unknown ROLE: ${ROLE}"
        exit 1
        ;;
esac

echo ""
echo "[INFO] Network configuration:"
ip addr show

echo ""
echo "[INFO] Node ${HOSTNAME} ready"
