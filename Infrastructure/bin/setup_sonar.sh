#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Sonarqube in project $GUID-sonarqube"

# Code to set up the SonarQube project.
# Ideally just calls a template
# oc new-app -f ../templates/sonarqube.yaml --param .....

# To be Implemented by Student

echo
echo
echo "#####################################################################"
echo "importing image for nexus3:latest in $GUID-nexus"
echo "#####################################################################"

oc import-image wkulhanek/sonarqube:6.7.4 --from=docker.io/redhat-gpte-devopsautomation/sonarqube:6.7.4 --confirm -n $GUID-sonarqube

# create volume claim
#echo
#echo
#echo "#####################################################################"
#echo "creating volume sonarqube_db for sonarqube in $GUID-nexus"
#oc create -f ../templates/sonarqube_db.yaml  -n $GUID-sonarqube
#echo "creating volume sonarqube-pvc for sonarqube in $GUID-nexus"
#oc create -f ../templates/sonarqube-pvc.yaml  -n $GUID-sonarqube
#echo "#####################################################################"


echo
echo
echo "#####################################################################"
echo "creating app APPLICATION_NAME=sonarqube in $GUID-nexus"
echo "#####################################################################"
oc new-app -f ../templates/sonarqube.yaml -p PROJECT_NAMESPACE=$GUID-sonarqube -p APPS_CLUSTER_HOSTNAME=apps.na39.openshift.opentlc.com -n $GUID-sonarqube

