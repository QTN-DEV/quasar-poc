## Checklist Bundled Threat Detection

### ClamAV

ClamAV is an open-source antivirus tool that scans for malware in email and on servers. It scans for malicious files in email attachments and on servers. Also it can detect many types of malware, including viruses. 


ClamAV is designed to scan files quickly. It includes a multi-threaded daemon, a command-line scanner, and a tool for automatic database updates. ClamAV supports many types of files, including standard mail file formats, archive formats, executable formats, and popular document formats. ClamAV is used for email and web scanning, and endpoint security. It can be used on Unix, AIX, BSD, HP-UX, Linux, macOS, OpenVMS, OSF (Tru64), Solaris, and Haiku. 

#### Directory Structure

```
clamav/
├── Dockerfile
├── README.md
├── clamav_inotify.service
├── clamav_inotify.sh
├── entrypoint.sh
└── wizard.sh
```

> FOR NOW THE SCRIPT IS REMAIN **ERROR**.