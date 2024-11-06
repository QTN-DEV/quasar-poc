## Checklist Bundled Threat Detection

### Osquery

Osquery is an open-source tool that helps organizations monitor and analyze devices on their network by using a SQL-like language to query the operating system. Queries devices using SQL-like language, collects and normalizes data independently of the operating system, supports multiple operating systems. It's used for security monitoring, IT operations, compliance activities, threat hunting, incident response

#### Directory Structure

```
osquery/
├── Dockerfile
├── README.md
├── entrypoint.sh
├── osquery.conf
└── wizard.sh
```

The Dockerfile containerized wazuh agent with osquery by running `entrypoint.sh`, which Start Osquery daemon directly, then Check if log file exists, wait for it to be created if necessary and last Tail the Osquery log to keep the container running.

> STILL FALSE NEGATIVE, BUT THE LOG IS FINE