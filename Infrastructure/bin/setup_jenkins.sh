#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# To be Implemented by Student
echo
echo
echo "#######################################################################################################"
echo "creating app APPLICATION_NAME=jenkins with persistent storage and sufficient resources in $GUID-jenkins"
echo "#######################################################################################################"
echo GUID=$GUID
echo REPO=$REPO
echo CLUSTER=$CLUSTER
oc new-app -f ../templates/jenkins.yaml -p APPLICATION_NAME=jenkins -p GUID=$GUID -p PROJECT_NAMESPACE=$GUID-jenkins -p APPS_CLUSTER_HOSTNAME=apps.$CLUSTER -n $GUID-jenkins


echo
echo
echo "##########################################################################################################################################"
echo "Create a build configuration to build the custom Maven slave pod to include Skopeo from openshift/jenkins-agent-maven-35-centos7:v3.11 in $GUID-jenkins"
echo "##########################################################################################################################################"

# oc import-image openshift/jenkins-agent-maven-35-centos7:v3.11 --from=docker.io/openshift/jenkins-agent-maven-35-centos7:v3.11 --confirm -n $GUID-jenkins

oc new-build  -D $'FROM docker.io/openshift/jenkins-agent-maven-35-centos7:v3.11\n
      USER root\nRUN yum -y install skopeo && yum clean all\n
      USER 1001' --name=jenkins-agent-appdev -n $GUID-jenkins

echo
echo
echo "##########################################################################################################################################"
echo "Set up 3 build configurations with pointers to the pipelines in the source code project."
echo
echo "Each build configuration needs to point to the source code repository and the respective contextDir. The build configurations also need the following environment variables:"
echo
echo " BuildConfig to Jenkinsfile file for MLBParks"
echo "   - Repository: https://github.com/skoussou/ocp_appdev_template"
echo "   - contextDir: MLBParks"
echo
echo " BuildConfig to Jenkinsfile file for Nationalparks"
echo "   - Repository: https://github.com/skoussou/ocp_appdev_template"
echo "   - contextDir: Nationalparks"
echo
echo " BuildConfig to Jenkinsfile file for ParksMap"
echo "   - Repository: https://github.com/skoussou/ocp_appdev_template"
echo "   - contextDir: ParksMap"
echo
echo "- GUID: The common GUID for all projects"
echo "- CLUSTER: The cluster base URL—for example, na39.openshift.opentlc.com"
echo  
echo "##########################################################################################################################################"

echo 
echo "##########################################################################################################################################"
echo
echo " TODO: BuildConfig for Pipeline for MLBParks"
echo
echo " TODO: BuildConfig for Pipeline for Nationalparks"
echo
echo " TODO: BuildConfig for Pipeline for ParksMap"
echo
echo "##########################################################################################################################################"


