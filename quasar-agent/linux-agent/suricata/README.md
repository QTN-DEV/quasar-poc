## Wazuh Agent Bundled Checklist

### Suricata

Suricata is a free, open-source cybersecurity tool that acts as both an Intrusion Detection System (IDS) and an Intrusion Prevention System (IPS). It is used by organizations to detect cyber threats and monitor networks for suspicious activity. Suricata's features include:

* Network security monitoring: Suricata can monitor networks for suspicious activity. 
* PCAP processing: Suricata can process PCAP. 
* Deep packet inspection: Suricata performs well with deep packet inspection. 
* Rule set and signature language: Suricata uses a rule set and signature language to detect and prevent threats.

#### Directory Structure

```
suricata/
├── Dockerfile
├── README.md
├── entrypoint.sh
└── wizard.sh
```

The Dockerfile containerized wazuh agent with suricata by running `entrypoint.sh`, which it's update the Wazuh agent configuration with the provided Manager IP and Agent Name. And the important one is update the Suricata configuration file with the container's IP as `HOME_NET` and add Suricata log monitoring configuration in Wazuh. Last the `wizard.sh` is how to test the script automatically and easier.