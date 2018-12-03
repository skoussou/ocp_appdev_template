#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student

echo "#################################################################################################"
echo " DONE:	Grant the correct permissions to the Jenkins service account"

oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-dev

echo 
echo " DONE:	Create a MongoDB database"

oc new-app -f ../templates/dev-project/stk-parks-dev-mongodb-WITHPARAMS-NEW-SECRETS.yaml -p DATABASE_SERVICE_NAME=mongodb -p MONGODB_ADMIN_PASSWORD=mongodb -p MONGODB_DATABASE=parks -p MONGODB_PASSWORD=mongodb -p MONGODB_USER=mongodb -l app=mongodb -n ${GUID}-parks-dev

echo sleeping 10 secs
sleep 10s

echo "Polling for mongodb to be ready"
while : ; do
  echo "Checking if mongodb is Ready..."
  #oc get pod -n ${GUID}-parks-dev|grep '\-1\-'|grep -v deploy|grep "1/1"
  #oc get pod -n ${GUID}-parks-dev|grep 'mongodb-.*-deploy'|grep -v deploy|grep "1/1"
  oc get pod -n ${GUID}-parks-dev|grep '\-1\-'|grep -v deploy|grep "1/1"
  [[ "$?" == "1" ]] || break
  echo "...no. Sleeping 10 seconds."
  sleep 10
done

echo 
echo " DONE:	Create binary build configurations for the pipelines to use for each microservice"

# Build locally (no jenkins yet) maven project --> mvn -s ../nexus_settings.xml clean package -DskipTests=true
#                                                 oc start-build mlbparks --from-file=./target/mlbparks.war 
oc new-build --binary=true --name="mlbparks" --image-stream=jboss-eap70-openshift:1.7 -l app=mlbparks -n ${GUID}-parks-dev

# Build locally (no jenkins yet) maven project --> mvn -s ../nexus_settings.xml clean package -Dmaven.test.skip=true
#                                                 oc start-build nationalparks --from-file=./target/nationalparks.jar
oc new-build --binary=true --name="nationalparks" --image-stream=redhat-openjdk18-openshift:1.2 -l app=nationalparks -n ${GUID}-parks-dev

# Build locally (no jenkins yet) maven project --> mvn -s ../nexus_settings.xml clean package spring-boot:repackage -DskipTests -Dcom.redhat.xpaas.repo.redhatga
#                                                 oc start-build parksmap --from-file=./target/parksmap.jar
oc new-build --binary=true --name="parksmap" --image-stream=redhat-openjdk18-openshift:1.2 -l app=parksmap -n ${GUID}-parks-dev

echo 
echo " DONE:	Create ConfigMaps for configuration of the applications"
echo "            Set APPNAME to the following values—the grading pipeline checks for these exact strings:"
echo "   	  - MLB Parks (Dev)"
echo "   	  - National Parks (Dev)"
echo "   	  - ParksMap (Dev)"
echo " DONE:	Set up placeholder deployment configurations for the three microservices"
echo " DONE:	Configure the deployment configurations using the ConfigMaps"
echo " DONE:	Set deployment hooks to populate the database for the back end services"
echo " DONE:	Set up liveness and readiness probes"
echo " DONE:	Expose and label the services properly (parksmap-backend)"

# oc create configmap mlbparks-config --from-literal=APPNAME='MLB Parks (Dev)' --from-literal=DB_HOST=mongodb --from-literal=DB_PORT=27017 --from-literal=DB_USERNAME=mongodb --from-literal=DB_PASSWORD=mongodb --from-literal=DB_NAME=parks -n stk-parks-dev
# Set probes
# oc rollout pause dc mlbparks
# oc set probe dc/mlbparks --liveness --failure-threshold=3 --initial-delay-seconds=60 -- echo ok 
# oc set probe dc/mlbparks --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/
# oc set deployment-hook dc/mlbparks --post --container=nationalparks -- curl -s http://nationalparks:8080/ws/data/load/ 
# oc rollout resume dc mlbparks
echo "Creating APPLICATION_NAME=mlbparks in ${GUID}-parks-dev"
#oc new-app -f ../templates/dev-project/stk-parks-dev-APP-MLBPARKS-dc-cm-secrets.yaml -p GUID=${GUID} -p APPLICATION_NAME=mlbparks -p CLUSTER_NAME=na39.openshift.opentlc.com -l app=mlbparks -n ${GUID}-parks-dev
oc new-app -f ../templates/dev-project/stk-parks-dev-APP-MLBPARKS-dc-cm-secrets.yaml -p GUID=${GUID} -p APPLICATION_NAME=mlbparks -p CLUSTER_NAME=$CLUSTER -l app=mlbparks -n ${GUID}-parks-dev

# oc create configmap nationalparks-config --from-literal=APPNAME='National Parks (Dev)' --from-literal=DB_HOST=mongodb --from-literal=DB_PORT=27017 --from-literal=DB_USERNAME=mongodb --from-literal=DB_PASSWORD=mongodb --from-literal=DB_NAME=parks -n stk-parks-dev
# Set probes
# oc rollout pause dc nationalparks
# oc set probe dc/nationalparks --liveness --failure-threshold=3 --initial-delay-seconds=60 -- echo ok 
# oc set probe dc/nationalparks --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/
# oc set deployment-hook dc/nationalparks --post --container=nationalparks -- curl -s http://nationalparks:8080/ws/data/load/ 
# oc rollout resume dc nationalparks
echo "Creating APPLICATION_NAME=nationalparks in ${GUID}-parks-dev"
#oc new-app -f ../templates/dev-project/stk-parks-dev-APP-NATIONALBPARKS-dc-cm-secrets.yaml -p GUID=${GUID} -p APPLICATION_NAME=nationalparks -p CLUSTER_NAME=na39.openshift.opentlc.com -l app=nationalparks -n ${GUID}-parks-dev
oc new-app -f ../templates/dev-project/stk-parks-dev-APP-NATIONALBPARKS-dc-cm-secrets.yaml -p GUID=${GUID} -p APPLICATION_NAME=nationalparks -p CLUSTER_NAME=$CLUSTER -l app=nationalparks -n ${GUID}-parks-dev

# oc create configmap parksmap-config --from-literal=APPNAME='ParksMap (Dev)' -n ${GUID}-parks-dev
# Set probes
# oc rollout pause dc parksmap
# oc set probe dc/parksmap --liveness --failure-threshold=3 --initial-delay-seconds=60 -- echo ok 
# oc set probe dc/parksmap --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/
# oc rollout resume dc parksmap
echo "Creating APPLICATION_NAME=parksmap in ${GUID}-parks-dev"
oc policy add-role-to-user view --serviceaccount=default
#oc new-app -f ../templates/dev-project/stk-parks-dev-APP-PARKSMAP-dc-cm-secrets.yaml -p GUID=${GUID} -p APPLICATION_NAME=parksmap -p CLUSTER_NAME=na39.openshift.opentlc.com -l app=parksmap -n ${GUID}-parks-dev
oc new-app -f ../templates/dev-project/stk-parks-dev-APP-PARKSMAP-dc-cm-secrets.yaml -p GUID=${GUID} -p APPLICATION_NAME=parksmap -p CLUSTER_NAME=$CLUSTER -l app=parksmap -n ${GUID}-parks-dev

echo "#################################################################################################"
