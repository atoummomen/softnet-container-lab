# Experiment 01 — Bind-Mount Entrypoint in Containerlab

## Goal

The original `basic-lab` topology copied `bin/entrypoint.sh` into the Docker image using the Dockerfile `COPY` instruction.

This experiment modifies the lab so that the entrypoint script is no longer baked into the image. Instead, it is bind-mounted from the host into each container at runtime through the Containerlab topology file.

---

## Original Behavior

In the original Dockerfile, the entrypoint was copied into the image:

```dockerfile
COPY --chmod=755 bin/entrypoint.sh /entrypoint.sh
```

This means that every modification to `bin/entrypoint.sh` required rebuilding the Docker image.

---

## Modified Behavior

The `COPY` instruction was removed from the Dockerfile.

The topology file now bind-mounts the host script into each container:

```yaml
binds:
  - bin/entrypoint.sh:/entrypoint.sh:ro
```

This makes the host file:

```text
bin/entrypoint.sh
```

available inside each container as:

```text
/entrypoint.sh
```

---

## Files Modified

- `containerlab/Dockerfile`
- `containerlab/basic-lab.clab.yml`

---

## Verification

The existing `exec` directive still works:

```yaml
exec:
  - bash /entrypoint.sh
```

Both nodes configure their interfaces correctly and can successfully ping each other over both IPv4 and IPv6.

---

## Test Commands

```bash
cd containerlab
./deploy.sh

containerlab inspect -t basic-lab.clab.yml

docker exec clab-basic-lab-node1 ls -l /entrypoint.sh
docker exec clab-basic-lab-node2 ls -l /entrypoint.sh

docker exec clab-basic-lab-node1 ping -c 3 10.0.0.2
docker exec clab-basic-lab-node1 ping -6 -c 3 fc00::2
```

---

## Result

The lab works exactly as before, but the entrypoint script is now provided through a runtime bind mount instead of being copied into the Docker image.

This improves the development workflow because the script can be modified directly on the host without rebuilding the container image.
