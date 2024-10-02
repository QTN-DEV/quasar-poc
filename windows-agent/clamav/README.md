## Checklist Bundled Threat Detection

### Suricata

This is how to run the Dockerfile along with `entrypoint.sh`

```
docker build -t quasar-agent:suricata .
docker run --name quasar-agent-container --net=bridge --cap-add=NET_ADMIN quasar-agent:suricata
docker exec -it quasar-agent-container /bin/bash
```
If we're using bridge network, set Suricata IDS to scan eth0. But if using host network, set interface to enX0.