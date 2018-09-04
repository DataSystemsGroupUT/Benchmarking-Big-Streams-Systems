#!/usr/bin/env bash
# This script has been used as a scratch.
# Last version of Resize droplet scripts has been migrated to remoteInvocation.sh

CONTENT_TYPE="'Content-Type: application/json'"
AUTH="'Authorization: Bearer 808fe5b62bc168f757a40463ee3dfdefc58f2d5b865b88ff1a0a1bad71a5154e'"
C1="c-1vcpu-2gb"
C16="'{"type":"resize","size":"c-16"}'"
C4="c-4"
C2="c-2"



function startPowerOff {
    echo "power off"

}

function stopPowerOn {
    echo "power on"

}


case $1 in
    off)
        runCommandMasterStreamServers "${STOP_SPARK_DSTREAM_PROC_CMD}" "nohup"
    ;;
    on)
        runCommandMasterStreamServers "${STOP_SPARK_DATASET_PROC_CMD}" "nohup"
    ;;
    *)
        echo "Which spark processing would you like to stop"
    ;;
esac

#Stream Servers
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C16}  "https://api.digitalocean.com/v2/droplets/99932869/actions"
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C16}  "https://api.digitalocean.com/v2/droplets/99932868/actions"
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C16}  "https://api.digitalocean.com/v2/droplets/99932867/actions"
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C16}  "https://api.digitalocean.com/v2/droplets/99932866/actions"
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C16}  "https://api.digitalocean.com/v2/droplets/99932865/actions"
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C16}  "https://api.digitalocean.com/v2/droplets/99932864/actions"
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C16}  "https://api.digitalocean.com/v2/droplets/99932863/actions"
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C16}  "https://api.digitalocean.com/v2/droplets/99932862/actions"
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C16}  "https://api.digitalocean.com/v2/droplets/99932861/actions"
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C16}  "https://api.digitalocean.com/v2/droplets/99932860/actions"

#Kafka Servers
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C16}  "https://api.digitalocean.com/v2/droplets/99933241/actions"
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C16}  "https://api.digitalocean.com/v2/droplets/99933240/actions"
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C16}  "https://api.digitalocean.com/v2/droplets/99933239/actions"
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C16}  "https://api.digitalocean.com/v2/droplets/99933238/actions"
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C16}  "https://api.digitalocean.com/v2/droplets/99933237/actions"





#ZooKeeper Servers
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C4}  "https://api.digitalocean.com/v2/droplets/99933379/actions"
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C4}  "https://api.digitalocean.com/v2/droplets/99933378/actions"
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C4}  "https://api.digitalocean.com/v2/droplets/99933377/actions"

#Redis Server
curl -X POST -H ${CONTENT_TYPE} -H ${AUTH} -d ${C4}  "https://api.digitalocean.com/v2/droplets/108622384/actions"

