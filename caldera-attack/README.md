# Installation Caldera on Docker

Tried installing Caldera 5.0.0? Too much hassle to get it up and running? Just to get familiar with Caldera? No problem at all. Install Caldera 4.1.0 instead in a few easy steps:

```
git clone https://github.com/mitre/caldera.git --recursive --branch 4.1.0
cd caldera
docker build . --build-arg WIN_BUILD=true -t caldera:latest
docker run -p 8888:8888 caldera:latest
```