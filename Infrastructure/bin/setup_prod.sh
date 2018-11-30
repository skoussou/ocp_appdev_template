#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Production Environment in project ${GUID}-parks-prod"

# Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

# To be Implemented by Student

echo "#################################################################################################"

echo " DONE:	Grant the correct permissions to the Jenkins service account"
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-prod

echo " DONE:	Grant the correct permissions to pull images from the development project"
oc policy add-role-to-group system:image-puller system:serviceaccounts:${GUID}-parks-prod -n ${GUID}-parks-dev

echo " DONE:	Grant the correct permissions for the ParksMap application to read back-end services (see the associated README file)"
oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-prod

echo "*******************************************************************************************"
echo " TODO:	Set up a replicated MongoDB database via StatefulSet with at least three replicas"
echo "*******************************************************************************************"
echo
echo

echo 'apiVersion: v1
kind: Service
metadata:
  name: "mongodb-internal"
  labels:
    name: "mongodb"
  annotations: 
    service.alpha.kubernetes.io/tolerate-unready-endpoints: "true"
spec:
  clusterIP: None
  ports:
    - name: mongodb
      port: 27017
  selector: 
    name: "mongodb"' | oc create -f -



echo 'kind: Service
apiVersion: v1
metadata:
  name: "mongodb"
spec:
  ports:
    - name: "mongodb"
      port: 27017
  selector:
    name: mongodb' | oc create -f -





echo 'apiVersion: apps/v1
kind: StatefulSet
metadata:
    name: "mongodb"
spec:
  serviceName: "mongodb-internal"
  replicas: 3
  selector:
    matchLabels:
      name: "mongodb"
  template:
    metadata:
      labels:
        name: "mongodb"
    spec:
      containers:
      - name: mongodb-container
        image: registry.access.redhat.com/rhscl/mongodb-32-rhel7:3.2
        args: 
          - "run-mongod-replication"
        ports:
        - containerPort: 27017
          name: mongodb
        volumeMounts:
        - name: "mongo-data"
          mountPath: "/var/lib/mongodb/data"
        resources:
          limits:
            cpu: "1"
            memory: 2Gi
          requests:
            cpu: "1"
            memory: 1Gi
        env:
          - name: MONGODB_DATABASE
            value: "mongodb"
          - name: MONGODB_USER
            value: "mongodb"
          - name: MONGODB_PASSWORD
            value: "mongodb"
          - name: MONGODB_ADMIN_PASSWORD
            value: "mongodb"
          - name: MONGODB_REPLICA_NAME
            value: "rs0"
          - name: MONGODB_KEYFILE_VALUE
            value: "12345678901234567890"
          - name: MONGODB_SERVICE_NAME
            value: "mongodb-internal"
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -i
            - -c
            - mongo 127.0.0.1:27017/$MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD
              --eval="quit()"
          failureThreshold: 3
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
          initialDelaySeconds: 15
  volumeClaimTemplates:
  - metadata:
      name: mongo-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 2Gi' | oc create -f -

echo
echo
echo " TODO:	Setting up blue and green instances for [mlbparks] of the three microservices"
echo
echo " TODO:	Use ConfigMaps to configure [mlbparks]"
echo "   	  Set APPNAME to the following values—the grading pipeline checks for these exact strings:"
echo "   	    - MLB Parks (Green)"
echo "   	    - MLB Parks (Blue)"
echo
echo
echo "------------------------------------------------------------------------"
echo " Microservice [mlbparks] Set up blue and green instances for [mlbparks] "
echo "------------------------------------------------------------------------"

# Add placeholder ConfigMaps.
#oc create configmap mlbparks-green-config --from-literal=APPNAME='MLB Parks (Green)' --from-literal=DB_HOST=mongodb --from-literal=DB_PORT=27017 --from-literal=DB_USERNAME=mongodb --from-literal=DB_PASSWORD=mongodb --from-literal=DB_NAME=parks --from-literal=DB_REPLICASET=rs0 -n ${GUID}-parks-prod
#oc create configmap mlbparks-blue-config --from-literal=APPNAME='MLB Parks (Blue)' --from-literal=DB_HOST=mongodb --from-literal=DB_PORT=27017 --from-literal=DB_USERNAME=mongodb --from-literal=DB_PASSWORD=mongodb --from-literal=DB_NAME=parks --from-literal=DB_REPLICASET=rs0 -n ${GUID}-parks-prod 

# Create two new deployment configurations: tasks-green and tasks-blue and point both to tasks:0.0.
# oc new-app ${GUID}-parks-dev/mlbparks:0.0 --name=mlbparks-blue --allow-missing-imagestream-tags=true -l app=mlbparks -n ${GUID}-parks-prod
# oc new-app ${GUID}-parks-dev/mlbparks:0.0 --name=mlbparks-green --allow-missing-imagestream-tags=true -l app=mlbparks -n ${GUID}-parks-prod

# oc rollout pause dc mlbparks-blue
# oc rollout pause dc mlbparks-green

# Turn off automatic building and deployment for both deployment configurations.
# oc set triggers dc/mlbparks-green --remove-all -n  ${GUID}-parks-prod
# oc set triggers dc/mlbparks-blue --remove-all -n  ${GUID}-parks-prod


# Create Readiness & Liveness probes
# oc set probe dc/mlbparks-green --liveness --failure-threshold=3 --initial-delay-seconds=60 -- echo ok -n  ${GUID}-parks-prod
# oc set probe dc/mlbparks-green --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n  ${GUID}-parks-prod
# oc set probe dc/mlbparks-blue --liveness --failure-threshold=3 --initial-delay-seconds=60 -- echo ok  -n  ${GUID}-parks-prod
# oc set probe dc/mlbparks-blue --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n  ${GUID}-parks-prod

# Adding env variables to template for mlbparks-green deployment (all avaulable in configmap mlbparks-green-config)
# oc set env dc/mlbparks-green --from=configmap/mlbparks-green-config -n  stk-parks-prod

# Adding env variables to template for mlbparks-blue deployment (all avaulable in configmap mlbparks-blue-config)
# oc set env dc/mlbparks-blue --from=configmap/mlbparks-blue-config -n  ${GUID}-parks-prod

# oc rollout resume dc mlbparks-blue
# oc rollout resume dc mlbparks-green

oc new-app -f ../templates/prod-project/stk-parks-prod-app-backend-DC.yaml -p GUID=${GUID} -p APPLICATION_NAME=mlbparks -p COLOR=blue -p APPNAME_LABEL="MLB Parks (Blue)" -l app=mlbparks -n ${GUID}-parks-prod
echo "------------------------------------------------------------------------"
oc new-app -f ../templates/prod-project/stk-parks-prod-app-backend-DC.yaml -p GUID=${GUID} -p APPLICATION_NAME=mlbparks -p COLOR=green -p APPNAME_LABEL="MLB Parks (Green)" -l app=mlbparks -n ${GUID}-parks-prod
echo
echo
echo " TODO:	Make the [mlbparks-green] service active initially to guarantee a Blue rollout upon the first pipeline run"

oc process -f ../templates/prod-project/stk-parks-prod-app-backend-SVC.yaml -p=DC_NAME=mlbparks-green -l app=mlbparks |oc create -f - -n ${GUID}-parks-prod
# oc create service clusterip mlbparks-green --tcp=8080:8080
# oc patch svc/mlbparks-green -p '{"metadata":{"labels":{"type":"parksmap-backend"}}}'
# oc process -f ../templates/prod-project/stk-parks-prod-app-backend-SVC.yaml -p=DC_NAME=mlbparks-green -l app=mlbparks |oc create -f -


echo
echo
echo " TODO:	Setting up blue and green instances for [nationalparks] of the three microservices"
echo
echo " TODO:	Use ConfigMaps to configure [nationalparks]"
echo "   	  Set APPNAME to the following values—the grading pipeline checks for these exact strings:"
echo "   	    - National Parks (Green)"
echo "   	    - National Parks (Blue)"
echo
echo
echo "------------------------------------------------------------------------"
echo " Microservice [nationalparks] Set up blue and green instances for [nationalparks] "
echo "------------------------------------------------------------------------"

oc new-app -f ../templates/prod-project/stk-parks-prod-app-backend-DC.yaml -p GUID=${GUID} -p APPLICATION_NAME=nationalparks -p COLOR=blue -p APPNAME_LABEL="National Parks (Blue)" -l app=nationalparks -n ${GUID}-parks-prod
echo "------------------------------------------------------------------------"
oc new-app -f ../templates/prod-project/stk-parks-prod-app-backend-DC.yaml -p GUID=${GUID} -p APPLICATION_NAME=nationalparks -p COLOR=green -p APPNAME_LABEL="National Parks (Green)" -l app=nationalparks -n ${GUID}-parks-prod

echo
echo
echo
echo " TODO:	Make the [mlbparks-green] service active initially to guarantee a Blue rollout upon the first pipeline run"

oc process -f ../templates/prod-project/stk-parks-prod-app-backend-SVC.yaml -p=DC_NAME=nationalparks-green -l app=nationalparks |oc create -f - -n ${GUID}-parks-prod


# oc create service clusterip mlbparks-green --tcp=8080:8080
# oc patch svc/mlbparks-green -p '{"metadata":{"labels":{"type":"parksmap-backend"}}}'
# oc process -f ../templates/prod-project/stk-parks-prod-app-backend-SVC.yaml -p=DC_NAME=nationalparks-green -l app=nationalparks |oc create -f -

echo
echo
echo " TODO:	Setting up blue and green instances for [parksmap] of the three microservices"
echo
echo " TODO:	Use ConfigMaps to configure [parksmap]"
echo "   	  Set APPNAME to the following values—the grading pipeline checks for these exact strings:"
echo "   	    - ParksMap (Green)"
echo "   	    - ParksMap (Blue)"
echo
echo
echo "------------------------------------------------------------------------"
echo " Microservice [parksmap] Set up blue and green instances for [parksmap] "
echo "------------------------------------------------------------------------"

oc new-app -f ../templates/prod-project/stk-parks-prod-app-frontend-DC.yaml -p GUID=${GUID} -p APPLICATION_NAME=parksmap -p COLOR=blue -p APPNAME_LABEL="ParksMap (Blue)" -l app=parksmap -n ${GUID}-parks-prod
echo "------------------------------------------------------------------------"
oc new-app -f ../templates/prod-project/stk-parks-prod-app-frontend-DC.yaml -p GUID=${GUID} -p APPLICATION_NAME=parksmap -p COLOR=green -p APPNAME_LABEL="ParksMap (Green)" -l app=parksmap -n ${GUID}-parks-prod
echo
echo
echo " TODO:	Make the [parksmap-green] service active initially to guarantee a Blue rollout upon the first pipeline run"

oc process -f ../templates/prod-project/stk-parks-prod-app-frontend-SVC.yaml -p=DC_NAME=parksmap-green -l app=parksmap |oc create -f - -n ${GUID}-parks-prod

echo " TODO: SERVICE required"
# oc process -f ../templates/prod-project/stk-parks-prod-app-backend-SVC.yaml -p=DC_NAME=parksmap-green -l app=parksmap |oc create -f -

echo " TODO: ROUTE required"
oc process -f ../templates/prod-project/stk-parks-prod-app-frontend-ROUTE.yaml -p=ROUTE_NAME=parksmap -p=SERVICE_NAME=parksmap-green -p=GUID=${GUID} -p=CLUSTER_NAME=na39.openshift.opentlc.com -l app=parksmap |oc create -f - -n ${GUID}-parks-prod

echo "#################################################################################################"
