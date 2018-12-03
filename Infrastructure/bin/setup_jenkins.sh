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
echo "##########################################################################################################################################"
echo "Create a build configuration to build the custom Maven slave pod to include Skopeo from openshift/jenkins-agent-maven-35-centos7:v3.11 in $GUID-jenkins"
echo "##########################################################################################################################################"

#oc import-image openshift/jenkins-agent-maven-35-centos7:v3.11 --from=docker.io/openshift/jenkins-agent-maven-35-centos7:v3.11 --confirm -n $GUID-jenkins

# NOTE: This agent pod if it is to be configured INSIDE JENKINGS
#oc new-build  -D $'FROM docker.io/openshift/jenkins-agent-maven-35-centos7:v3.11\n
#      USER root\nRUN yum -y install skopeo && yum clean all\n
#      USER 1001' --name=jenkins-agent-appdev -n $GUID-jenkins

# NOTE: This slave pod if it is to be delegated to a new pod AND SUPER IMPORTANT the label so it gets attached as slave by JENKINS
oc new-build  -D $'FROM docker.io/openshift/jenkins-slave-maven-centos7:v3.11\n
      USER root\nRUN yum -y install skopeo && yum clean all\n
      USER 1001' --name=jenkins-slave-appdev -n $GUID-jenkins -l role=jenkins-slave

echo
echo "<----------------------------------------->"
echo "Polling for jenkins slave image is ready"
while : ; do
  echo "Checking if jenkins slave image has been built..."
  #oc get pod -n ${GUID}-parks-dev|grep '\-1\-'|grep -v deploy|grep "1/1"
  #oc get pod -n ${GUID}-parks-dev|grep 'mongodb-.*-deploy'|grep -v deploy|grep "1/1"
  
  oc get is -n ${GUID}-jenkins|grep 'jenkins-slave-appdev'|grep "latest"

  [[ "$?" == "1" ]] || break
  echo "...no. Sleeping 10 seconds."
  sleep 10
done
#echo sleeping 15
#sleep 15

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
echo "<----------------------------------------->"
echo "Polling for jenkins to be ready"
while : ; do
  echo "Checking if jenkins is Ready..."
  #oc get pod -n ${GUID}-parks-dev|grep '\-1\-'|grep -v deploy|grep "1/1"
  #oc get pod -n ${GUID}-parks-dev|grep 'mongodb-.*-deploy'|grep -v deploy|grep "1/1"
  oc get pod -n ${GUID}-jenkins|grep '\-1\-'|grep -v deploy|grep "1/1"
  [[ "$?" == "1" ]] || break
  echo "...no. Sleeping 10 seconds."
  sleep 10
done

#sleep 20

echo 
echo "##########################################################################################################################################"
echo "Set up 3 build configurations with pointers to the pipelines in the source code project."
echo
echo
echo " DONE: BuildConfig for Pipeline for MLBParks"
echo "   - Repository: https://github.com/skoussou/ocp_appdev_template"
echo "   - contextDir: MLBParks"
echo
#oc new-app -f ../templates/jenkins-bc-pipeline.yaml -p GUID=stk -p CLUSTER_NAME=na39.openshift.opentlc.com -p APPLICATION_NAME=mlbparks -p CONTEXT_DIR=MLBParks -n stk-jenkin
oc new-app -f ../templates/jenkins-bc-pipeline.yaml -p GUID=$GUID -p CLUSTER_NAME=$CLUSTER -p APPLICATION_NAME=mlbparks -p CONTEXT_DIR=MLBParks -n $GUID-jenkins

echo
echo " DONE: BuildConfig for Pipeline for Nationalparks"
echo "   - Repository: https://github.com/skoussou/ocp_appdev_template"
echo "   - contextDir: Nationalparks"
echo
# oc new-app -f ../templates/jenkins-bc-pipeline.yaml -p GUID=stk -p CLUSTER_NAME=na39.openshift.opentlc.com -p APPLICATION_NAME=nationalparks -p CONTEXT_DIR=Nationalparks -n stk-jenkins
oc new-app -f ../templates/jenkins-bc-pipeline.yaml -p GUID=$GUID -p CLUSTER_NAME=$CLUSTER -p APPLICATION_NAME=nationalparks -p CONTEXT_DIR=Nationalparks -n $GUID-jenkins

echo
echo " DONE: BuildConfig for Pipeline for ParksMap"
echo "   - Repository: https://github.com/skoussou/ocp_appdev_template"
echo "   - contextDir: ParksMap"
echo
#oc new-app -f ../templates/jenkins-bc-pipeline.yaml -p GUID=stk -p CLUSTER_NAME=na39.openshift.opentlc.com -p APPLICATION_NAME=parksmap -p CONTEXT_DIR=ParksMap -n stk-jenkins
oc new-app -f ../templates/jenkins-bc-pipeline.yaml -p GUID=$GUID -p CLUSTER_NAME=$CLUSTER -p APPLICATION_NAME=parksmap -p CONTEXT_DIR=ParksMap -n $GUID-jenkins
echo "##########################################################################################################################################"


