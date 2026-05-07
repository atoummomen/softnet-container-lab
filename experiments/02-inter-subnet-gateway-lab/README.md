# Experiment 02 — Inter-Subnet Gateway Lab

## Goal

Build a three-node Containerlab topology where two hosts are placed on separate IPv4 and IPv6 subnets and communicate through a Linux router container.

The required topology is:

```text
hs1 <--> rt1 <--> hs2
```

- `hs1` and `hs2` are hosts
- `rt1` is the gateway/router between the two subnets

---

## Topology

```text
+------+        +------+        +------+
| hs1  | eth1   | rt1  | eth2   | hs2  |
|      |--------|      |--------|      |
+------+        +------+        +------+
          eth1
```

Links:

```text
hs1:eth1 <--> rt1:eth1
rt1:eth2 <--> hs2:eth1
```

---

## Addressing Plan

### IPv4

| Node | Interface | IPv4 Address | Subnet |
|------|------------|---------------|---------|
| hs1  | eth1 | 10.0.1.2/24 | 10.0.1.0/24 |
| rt1  | eth1 | 10.0.1.1/24 | 10.0.1.0/24 |
| rt1  | eth2 | 10.0.2.1/24 | 10.0.2.0/24 |
| hs2  | eth1 | 10.0.2.2/24 | 10.0.2.0/24 |

### IPv6

| Node | Interface | IPv6 Address | Subnet |
|------|------------|---------------|---------|
| hs1  | eth1 | fc00:1::2/64 | fc00:1::/64 |
| rt1  | eth1 | fc00:1::1/64 | fc00:1::/64 |
| rt1  | eth2 | fc00:2::1/64 | fc00:2::/64 |
| hs2  | eth1 | fc00:2::2/64 | fc00:2::/64 |

---

## Routing Design

`hs1` and `hs2` are placed on different subnets.

The hosts do not know specific routes to the remote subnet.  
Each host only knows:

1. Its directly connected subnet
2. A default gateway pointing to `rt1`

### hs1 Routes

IPv4:

```text
10.0.1.0/24 dev eth1
default via 10.0.1.1 dev eth1
```

IPv6:

```text
fc00:1::/64 dev eth1
default via fc00:1::1 dev eth1
```

### hs2 Routes

IPv4:

```text
10.0.2.0/24 dev eth1
default via 10.0.2.1 dev eth1
```

IPv6:

```text
fc00:2::/64 dev eth1
default via fc00:2::1 dev eth1
```

### rt1 Routes

`rt1` is directly connected to both subnets:

```text
10.0.1.0/24 dev eth1
10.0.2.0/24 dev eth2
```

```text
fc00:1::/64 dev eth1
fc00:2::/64 dev eth2
```

IPv4 and IPv6 forwarding are enabled on `rt1`.

---

## Files Modified

```text
containerlab/inter-subnet-gateway-lab.clab.yml
containerlab/bin/entrypoint.sh
containerlab/configs/hs1.cfg
containerlab/configs/rt1.cfg
containerlab/configs/hs2.cfg
containerlab/deploy.sh
containerlab/destroy.sh
```

---

## Automatic Configuration

All network configuration is applied automatically during deployment through the Containerlab `exec` directive:

```yaml
exec:
  - bash /entrypoint.sh
```

The same `entrypoint.sh` script is used by all nodes.

The behavior depends on the node role defined in each config file:

```bash
ROLE="host"
```

or:

```bash
ROLE="router"
```

Host nodes configure:

```text
eth1 address
IPv4 default route
IPv6 default route
```

The router node configures:

```text
eth1 toward hs1
eth2 toward hs2
IPv4 forwarding
IPv6 forwarding
```

---

## Deploy

```bash
cd containerlab
./deploy.sh
```

Inspect the topology:

```bash
containerlab inspect -t inter-subnet-gateway-lab.clab.yml
```

Check running containers:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
```

---

## Verification Commands

### Check Node Hostnames

```bash
docker exec clab-inter-subnet-gateway-lab-hs1 hostname
docker exec clab-inter-subnet-gateway-lab-rt1 hostname
docker exec clab-inter-subnet-gateway-lab-hs2 hostname
```

Expected:

```text
hs1
rt1
hs2
```

---

### Check Interface Addressing

```bash
docker exec clab-inter-subnet-gateway-lab-hs1 ip addr show eth1
docker exec clab-inter-subnet-gateway-lab-rt1 ip addr show eth1
docker exec clab-inter-subnet-gateway-lab-rt1 ip addr show eth2
docker exec clab-inter-subnet-gateway-lab-hs2 ip addr show eth1
```

---

### Check IPv4 Routes

```bash
docker exec clab-inter-subnet-gateway-lab-hs1 ip route
docker exec clab-inter-subnet-gateway-lab-rt1 ip route
docker exec clab-inter-subnet-gateway-lab-hs2 ip route
```

---

### Check IPv6 Routes

```bash
docker exec clab-inter-subnet-gateway-lab-hs1 ip -6 route
docker exec clab-inter-subnet-gateway-lab-rt1 ip -6 route
docker exec clab-inter-subnet-gateway-lab-hs2 ip -6 route
```

---

### Check Router Forwarding

IPv4 forwarding:

```bash
docker exec clab-inter-subnet-gateway-lab-rt1 cat /proc/sys/net/ipv4/ip_forward
```

Expected:

```text
1
```

IPv6 forwarding:

```bash
docker exec clab-inter-subnet-gateway-lab-rt1 cat /proc/sys/net/ipv6/conf/all/forwarding
```

Expected:

```text
1
```

---

## Connectivity Tests

### IPv4: hs1 to hs2

```bash
docker exec clab-inter-subnet-gateway-lab-hs1 ping -c 3 10.0.2.2
```

### IPv4: hs2 to hs1

```bash
docker exec clab-inter-subnet-gateway-lab-hs2 ping -c 3 10.0.1.2
```

### IPv6: hs1 to hs2

```bash
docker exec clab-inter-subnet-gateway-lab-hs1 ping -6 -c 3 fc00:2::2
```

### IPv6: hs2 to hs1

```bash
docker exec clab-inter-subnet-gateway-lab-hs2 ping -6 -c 3 fc00:1::2
```

Successful output should show:

```text
3 packets transmitted, 3 received, 0% packet loss
```

---

## Router Reachability Tests

The router should be able to reach both hosts.

### IPv4

```bash
docker exec clab-inter-subnet-gateway-lab-rt1 ping -c 3 10.0.1.2
docker exec clab-inter-subnet-gateway-lab-rt1 ping -c 3 10.0.2.2
```

### IPv6

```bash
docker exec clab-inter-subnet-gateway-lab-rt1 ping -6 -c 3 fc00:1::2
docker exec clab-inter-subnet-gateway-lab-rt1 ping -6 -c 3 fc00:2::2
```

---

## Bind-Mounted Entrypoint

The entrypoint script is not copied into the Docker image.

It is bind-mounted into each container:

```yaml
binds:
  - bin/entrypoint.sh:/entrypoint.sh:ro
```

Verify:

```bash
docker exec clab-inter-subnet-gateway-lab-hs1 ls -l /entrypoint.sh
docker exec clab-inter-subnet-gateway-lab-rt1 ls -l /entrypoint.sh
docker exec clab-inter-subnet-gateway-lab-hs2 ls -l /entrypoint.sh
```

---

## Destroy

```bash
./destroy.sh
```

---

## Result

This experiment implements a dual-stack routed topology in Containerlab.

`hs1` and `hs2` are placed on separate IPv4 and IPv6 subnets.  
Each host uses `rt1` as its default gateway.  
`rt1` forwards traffic between both subnets using IPv4 and IPv6 forwarding.

The final result is that `hs1` can reach `hs2`, and `hs2` can reach `hs1`, through the router container.
