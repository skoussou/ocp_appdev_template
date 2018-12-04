#!/bin/bash
# Setup Nexus Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Nexus in project $GUID-nexus"

# Code to set up the Nexus. It will need to
# * Create Nexus
# * Set the right options for the Nexus Deployment Config
# * Load Nexus with the right repos
# * Configure Nexus as a docker registry
# Hint: Make sure to wait until Nexus if fully up and running
#       before configuring nexus with repositories.
#       You could use the following code:
# while : ; do
#   echo "Checking if Nexus is Ready..."
#   oc get pod -n ${GUID}-nexus|grep '\-2\-'|grep -v deploy|grep "1/1"
#   [[ "$?" == "1" ]] || break
#   echo "...no. Sleeping 10 seconds."
#   sleep 10
# done

# Ideally just calls a template
# oc new-app -f ./Infrastructure/templates/nexus.yaml --param .....

# To be Implemented by Student
echo
echo
echo "#####################################################################"
echo "importing image for nexus3:latest in $GUID-nexus"
echo "#####################################################################"

oc import-image openshift/nexus3:latest --from=docker.io/sonatype/nexus3:latest --confirm -n $GUID-nexus

# create volume claim
echo
echo
echo "#####################################################################"
echo "creating volume nexus-pvc for nexus3 in $GUID-nexus"
oc create -f ./Infrastructure/templates/nexus-pvc.yaml  -n $GUID-nexus
echo "#####################################################################"
# 
echo
echo
echo "#####################################################################"
echo "creating app APPLICATION_NAME=nexus3 in $GUID-nexus"
echo "#####################################################################"
#oc new-app -f ./Infrastructure/templates/nexus.yaml -p APPLICATION_NAME=nexus3 -p PROJECT_NAMESPACE=$GUID-nexus -p APPS_CLUSTER_HOSTNAME=apps.na39.openshift.opentlc.com -l app=nexus3 -n $GUID-nexus
oc new-app -f ./Infrastructure/templates/nexus.yaml -p APPLICATION_NAME=nexus3 -p PROJECT_NAMESPACE=$GUID-nexus -p APPS_CLUSTER_HOSTNAME=$CLUSTER -l app=nexus3 -n $GUID-nexus
# add claim to DC
# oc rollout pause dc nexus3
# oc set volume dc/nexus3 --add --overwrite --name=nexus3-volume-1 --mount-path=/nexus-data/ --type persistentVolumeClaim --claim-name=nexus-pvc
# oc rollout resume dc nexus3

# setup repositories script
# Hint: Make sure to wait until Nexus if fully up and running
#       before configuring nexus with repositories.
#       You could use the following code:
while : ; do
  echo "Checking if Nexus is Ready..."
  oc get pod -n ${GUID}-nexus|grep '\-1\-'|grep -v deploy|grep "1/1"
  [[ "$?" == "1" ]] || break
  echo "...no. Sleeping 10 seconds."
  sleep 10
done

sleep 10s

# annotate correctly the routes for console
echo
echo
echo "#####################################################################"
echo "annotating routes"
echo "#####################################################################"
oc annotate route nexus3 console.alpha.openshift.io/overview-app-route=true --overwrite
oc annotate route nexus-registry console.alpha.openshift.io/overview-app-route=false --overwrite

echo
echo
echo "#####################################################################"
echo "Configuring NEXUS"
echo "./Infrastructure/templates/setup_nexus3.sh admin admin123 http://$(oc get route nexus3 --template='{{ .spec.host }}')"
echo "#####################################################################"

SCRIPT_PATH="./Infrastructure/extras/configure_nexus3.sh"
source "$SCRIPT_PATH"
. "$SCRIPT_PATH" admin admin123 http://$(oc get route nexus3 --template='{{ .spec.host }}')

