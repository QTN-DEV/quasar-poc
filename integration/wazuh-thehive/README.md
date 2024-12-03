# TheHive, Cortex, and Shuffle Integration with Docker Compose

This project provides a lightweight and secure Docker Compose setup for deploying **TheHive**, **Cortex**, and integrating with **Shuffle** for advanced automation.

---

## Features
- **TheHive**: Incident Response Platform
- **Cortex**: Threat Analysis and Automation Engine
- **Cassandra**: Database backend for TheHive
- **Elasticsearch**: Indexing backend for TheHive
- **MinIO**: Object storage for file and attachment management
- **Shuffle**: Automation Platform with Webhook Integration

---

## Prerequisites
- **Docker**: [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose**: [Install Docker Compose](https://docs.docker.com/compose/install/)

---

## Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/your-repo/thehive-cortex-docker.git
cd thehive-cortex-docker
```

### 2. Configure Environment Variables
- Copy `.env.example` to `.env`:
    ```bash
    cp .env.example .env
    ```
- Edit the `.env` file to set custom values for ports, secrets, and credentials.

### 3. Start the Services
```bash
docker-compose up -d
```

### 4. Verify the Deployment
```bash
docker-compose ps
```

---

## Accessing Services
- **TheHive**: `http://<your-server-ip>:9000`
- **Cortex**: `http://<your-server-ip>:9001`

---

## Managing Services
- **Stop Services**:
    ```bash
    docker-compose down
    ```
- **View Logs**:
    ```bash
    docker-compose logs -f
    ```

---

## Environment Variables
Edit the `.env` file for custom configuration. Below are some key variables:

- **TheHive**:
    - `THEHIVE_PORT` (default: `9000`)
    - `THEHIVE_SECRET`
- **Cassandra**:
    - `CASSANDRA_PORT` (default: `9042`)
    - `CASSANDRA_CLUSTER_NAME`
- **Elasticsearch**:
    - `ELASTICSEARCH_PORT` (default: `9500`)
    - `ELASTICSEARCH_JAVA_OPTS`
- **MinIO**:
    - `MINIO_PORT` (default: `9002`)
    - `MINIO_ROOT_USER`
    - `MINIO_ROOT_PASSWORD`
- **Cortex**:
    - `CORTEX_PORT` (default: `9001`)

---

## Integration with Shuffle

### 1. Create a Workflow in Shuffle
- Access Shuffle and create a new workflow.
- Add a **Webhook Trigger** to the workflow.
- Copy the webhook URI and start the webhook.

### 2. Configure Wazuh to Forward Alerts
- Edit the Wazuh server configuration file `/var/ossec/etc/ossec.conf`.
- Add the following configuration, replacing `<YOUR_SHUFFLE_URL>` and `<HOOK_ID>` with the webhook URI from Shuffle:

```xml
<integration>
  <name>shuffle</name>
  <hook_url>http://<YOUR_SHUFFLE_URL>/api/v1/hooks/<HOOK_ID></hook_url>
  <level>3</level>
  <alert_format>json</alert_format>
</integration>
```

**Note**:
- The example above forwards all alerts of level `3` and above to Shuffle.
- To customize, you can replace the `<level>` tag with:
    - `<rule_id>`: To forward specific alerts.
    - `<group>`: To forward all alerts belonging to a rule group.
    - `<event_location>`: To forward alerts from a specified event location.

### 3. Complete the Workflow on Shuffle
- Use Shuffle to configure actions triggered by the received alerts.

---

## Configuring the Webhook on Wazuh Server

***STEP1 - Install Python & PIP on your Wazuh server*** <br>

This lab assumes you are using the provided Wazuh VirtualBox image (.OVA) that I used, which did not have Python preinstalled.

```
sudo yum update
sudo yum install python3
```
***STEP2 - Install The Hive Python module using PIP*** <br>

This is the Python module that will be referenced in the custom integration script that we will be creating in the next step. I have tested this module with version 5.2.1 of The Hive and its working at the time of this writeup.

```
sudo /var/ossec/framework/python/bin/pip3 install thehive4py
```
***STEP3 - Creating the custom integration script*** <br>

The below script will need to be created in /var/ossec/integrations/ and called custom-w2thive.py I used nano to create/edit the script, however, you can use whatever text editor you like for this.<br>
<br>
This script has the `lvl_threshold` variable set to `0`, meaning that all alerts created by Wazuh will be forwarded to The Hive. This has the potential to create a lot of noise if you have a lot of agents you are monitoring on your network so you may want to consider setting this to a higher level to only alert on more serious classifications. Please check the Wazuh ruleset classifications in the [manual](https://documentation.wazuh.com/current/user-manual/ruleset/rules-classification.html) they range from 0 - 15 with explanations for each. 

```python
#!/var/ossec/framework/python/bin/python3
import json
import sys
import os
import re
import logging
import uuid
from thehive4py.api import TheHiveApi
from thehive4py.models import Alert, AlertArtifact
#start user config
# Global vars
#threshold for wazuh rules level
lvl_threshold=0
#threshold for suricata rules level
suricata_lvl_threshold=3
debug_enabled = False
#info about created alert
info_enabled = True
#end user config
# Set paths
pwd = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
log_file = '{0}/logs/integrations.log'.format(pwd)
logger = logging.getLogger(__name__)
#set logging level
logger.setLevel(logging.WARNING)
if info_enabled:
    logger.setLevel(logging.INFO)
if debug_enabled:
    logger.setLevel(logging.DEBUG)
# create the logging file handler
fh = logging.FileHandler(log_file)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
fh.setFormatter(formatter)
logger.addHandler(fh)

def main(args):
    logger.debug('#start main')
    logger.debug('#get alert file location')
    alert_file_location = args[1]
    logger.debug('#get TheHive url')
    thive = args[3]
    logger.debug('#get TheHive api key')
    thive_api_key = args[2]
    thive_api = TheHiveApi(thive, thive_api_key )
    logger.debug('#open alert file')
    w_alert = json.load(open(alert_file_location))
    logger.debug('#alert data')
    logger.debug(str(w_alert))
    logger.debug('#gen json to dot-key-text')
    alt = pr(w_alert,'',[])
    logger.debug('#formatting description')
    format_alt = md_format(alt)
    logger.debug('#search artifacts')
    artifacts_dict = artifact_detect(format_alt)
    alert = generate_alert(format_alt, artifacts_dict, w_alert)
    logger.debug('#threshold filtering')
    if w_alert['rule']['groups']==['ids','suricata']:
        #checking the existence of the data.alert.severity field
        if 'data' in w_alert.keys():
            if 'alert' in w_alert['data']:
                #checking the level of the source event
                if int(w_alert['data']['alert']['severity'])<=suricata_lvl_threshold:
                    send_alert(alert, thive_api)
    elif int(w_alert['rule']['level'])>=lvl_threshold:
        #if the event is different from suricata AND suricata-event-type: alert check lvl_threshold
        send_alert(alert, thive_api)

def pr(data,prefix, alt):
    for key,value in data.items():
        if hasattr(value,'keys'):
            pr(value,prefix+'.'+str(key),alt=alt)
        else:
            alt.append((prefix+'.'+str(key)+'|||'+str(value)))
    return alt

def md_format(alt,format_alt=''):
    md_title_dict = {}
    #sorted with first key
    for now in alt:
        now = now[1:]
        #fix first key last symbol
        dot = now.split('|||')[0].find('.')
        if dot==-1:
            md_title_dict[now.split('|||')[0]] =[now]
        else:
            if now[0:dot] in md_title_dict.keys():
                (md_title_dict[now[0:dot]]).append(now)
            else:
                md_title_dict[now[0:dot]]=[now]
    for now in md_title_dict.keys():
        format_alt+='### '+now.capitalize()+'\n'+'| key | val |\n| ------ | ------ |\n'
        for let in md_title_dict[now]:
            key,val = let.split('|||')[0],let.split('|||')[1]
            format_alt+='| **' + key + '** | ' + val + ' |\n'
    return format_alt

def artifact_detect(format_alt):
    artifacts_dict = {}
    artifacts_dict['ip'] = re.findall(r'\d+\.\d+\.\d+\.\d+',format_alt)
    artifacts_dict['url'] =  re.findall(r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+',format_alt)
    artifacts_dict['domain'] = []
    for now in artifacts_dict['url']: artifacts_dict['domain'].append(now.split('//')[1].split('/')[0])
    return artifacts_dict

def generate_alert(format_alt, artifacts_dict,w_alert):
    #generate alert sourceRef
    sourceRef = str(uuid.uuid4())[0:6]
    artifacts = []
    if 'agent' in w_alert.keys():
        if 'ip' not in w_alert['agent'].keys():
            w_alert['agent']['ip']='no agent ip'
    else:
        w_alert['agent'] = {'id':'no agent id', 'name':'no agent name'}
    for key,value in artifacts_dict.items():
        for val in value:
            artifacts.append(AlertArtifact(dataType=key, data=val))
    alert = Alert(title=w_alert['rule']['description'],
              tlp=2,
              tags=['wazuh', 
              'rule='+w_alert['rule']['id'], 
              'agent_name='+w_alert['agent']['name'],
              'agent_id='+w_alert['agent']['id'],
              'agent_ip='+w_alert['agent']['ip'],],
              description=format_alt ,
              type='wazuh_alert',
              source='wazuh',
              sourceRef=sourceRef,
              artifacts=artifacts,)
    return alert

def send_alert(alert, thive_api):
    response = thive_api.create_alert(alert)
    if response.status_code == 201:
        logger.info('Create TheHive alert: '+ str(response.json()['id']))
    else:
        logger.error('Error create TheHive alert: {}/{}'.format(response.status_code, response.text))

if __name__ == "__main__":
    try:
       logger.debug('debug mode') # if debug enabled       
       # Main function
       main(sys.argv)
    except Exception:
       logger.exception('EGOR')
```
Next, we need to create a bash script called `custom-w2thive` and place it in `/var/ossec/integrations/custom-w2thive` which is needed to properly execute the .py script created above.

```sh
#!/bin/sh
# Copyright (C) 2015-2020, Wazuh Inc.
# Created by Wazuh, Inc. <info@wazuh.com>.
# This program is free software; you can redistribute it and/or modify it under the terms of GP>
WPYTHON_BIN="framework/python/bin/python3"
SCRIPT_PATH_NAME="$0"
DIR_NAME="$(cd $(dirname ${SCRIPT_PATH_NAME}); pwd -P)"
SCRIPT_NAME="$(basename ${SCRIPT_PATH_NAME})"
case ${DIR_NAME} in
    */active-response/bin | */wodles*)
        if [ -z "${WAZUH_PATH}" ]; then
            WAZUH_PATH="$(cd ${DIR_NAME}/../..; pwd)"
        fi
    PYTHON_SCRIPT="${DIR_NAME}/${SCRIPT_NAME}.py"
    ;;
    */bin)
    if [ -z "${WAZUH_PATH}" ]; then
        WAZUH_PATH="$(cd ${DIR_NAME}/..; pwd)"
    fi
    PYTHON_SCRIPT="${WAZUH_PATH}/framework/scripts/${SCRIPT_NAME}.py"
    ;;
     */integrations)
        if [ -z "${WAZUH_PATH}" ]; then
            WAZUH_PATH="$(cd ${DIR_NAME}/..; pwd)"
        fi
    PYTHON_SCRIPT="${DIR_NAME}/${SCRIPT_NAME}.py"
    ;;
esac
${WAZUH_PATH}/${WPYTHON_BIN} ${PYTHON_SCRIPT} $@
```
***STEP4 - Setting up permissions and ownership*** <br>

In this step, we make sure that Wazuh has the correct permissions to run the above scripts that we just created. 

```
sudo chmod 755 /var/ossec/integrations/custom-w2thive.py
sudo chmod 755 /var/ossec/integrations/custom-w2thive
sudo chown root:wazuh /var/ossec/integrations/custom-w2thive.py
sudo chown root:wazuh /var/ossec/integrations/custom-w2thive
```

***STEP5 - Final integration step - enabling the integration in the Wazuh manager configuration file*** <br>

You will need to use your preferred text editor to modify `/var/ossec/etc/ossec.conf` and insert the below code. You will need to insert the IP address for your The Hive server inside the `<hook_url>` tags as well as insert your API key inside the `<api_key>` tags. I have placed the code in my case just under the `</global>` tag in the config, make sure that your indentations match up to avoid running into issues.

```xml
<ossec_config>
…
  <integration>
    <name>custom-w2thive</name>
    <hook_url>http://TheHive_Server_IP:9000</hook_url>
    <api_key>RWw/Ii0yE6l+Nnd3nv3o3Uz+5UuHQYTM</api_key>
    <alert_format>json</alert_format>
  </integration>
…
</ossec_config>
```

Once complete, you need to restart Wazuh Manager:

`sudo systemctl restart wazuh-manager`

If all went well, you should shortly see alerts being generated under the `Alerts` tab in The Hive.


---
## Troubleshooting
- **Services not accessible**: Verify the configured ports in `.env`.
- **Logs**: View logs for individual services using:
    ```bash
    docker-compose logs thehive
    docker-compose logs cortex
    ```
- **Firewall Configuration**: Ensure required ports are open.

---

## Notes
- Place `.env` in the same directory as `docker-compose.yml` for automatic loading.
- Use secure secrets and credentials when editing `.env`.

---

Enjoy your deployment and automation with **TheHive**, **Cortex**, and **Wazuh**! 🚀