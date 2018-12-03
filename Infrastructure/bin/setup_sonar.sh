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
echo "importing image for  sonarqube:6.7.4in $GUID-sonarqube"
echo "#####################################################################"

oc import-image wkulhanek/sonarqube:6.7.4 --from=docker.io/wkulhanek/sonarqube --confirm -n $GUID-sonarqube
#oc import-image sonarqube --from=docker.io/redhat-gpte-devopsautomation/sonarqube:6.7.4 --confirm -n $GUID-sonarqube

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
echo "creating app APPLICATION_NAME=sonarqube in $GUID-sonarqube"
echo "#####################################################################"
#oc new-app -f ../templates/sonarqube.yaml -p GUID=$GUID -p PROJECT_NAMESPACE=$GUID-sonarqube -p APPS_CLUSTER_HOSTNAME=apps.na39.openshift.opentlc.com -n $GUID-sonarqube
oc new-app -f ../templates/sonarqube.yaml -p GUID=$GUID -p PROJECT_NAMESPACE=$GUID-sonarqube -p APPS_CLUSTER_HOSTNAME=$CLUSTER -n $GUID-sonarqube
