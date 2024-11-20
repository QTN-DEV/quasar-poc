## Checklist Bundled Threat Detection

### YARA

YARA is a tool aimed at (but not limited to) helping malware researchers to identify and classify malware samples. YARA stands for "Yet Another Recursive Acronym". It's a pattern-matching tool that uses rules to scan files and networks for patterns, scripts, and signatures that indicate malware.

YARA rules are instructions that define the characteristics of a specific type of malware or threat. They consist of a set of strings and a boolean expression. YARA can be used to detect simple attempts by inexperienced hackers, as well as more dangerous attempts by cybercriminals, corporate spies, or disgruntled employees. It can also be used to scan backups for health and recoverability. 

YARA is multi-platform and can run on Windows, Linux, and Mac OS X. It can be used through its command-line interface or from Python scripts. YARA rules are often used as part of emergency mitigation techniques to help detect critical 0-day vulnerabilities.

#### Directory Structure
```output
yara/
├── Dockerfile
├── README.md
├── entrypoint.sh
├── wizard.sh
└── yara.sh
```

In this directory structure, the Dockerfile containerized wazuh agent and yara program by installing it's dependency, installing YARA and wazuh agent binary. Then run the `entrypoint.sh` and `yara.sh` to ensure required environment variables are provided, and configure the directory for YARA scanning in Wazuh config. Last the `wizard.sh` is how to test the script automatically and easier.