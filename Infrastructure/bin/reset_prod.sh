#!/bin/bash
# Reset Production Project (initial active services: Blue)
# This sets all services to the Blue service so that any pipeline run will deploy Green
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Resetting Parks Production Environment in project ${GUID}-parks-prod to Green Services"

# Code to reset the parks production environment to make
# all the green services/routes active.
# This script will be called in the grading pipeline
# if the pipeline is executed without setting
# up the whole infrastructure to guarantee a Blue
# rollout followed by a Green rollout.

# To be Implemented by Student
oc delete service mlbparks-green --ignore-not-found=true
oc delete service mlbparks-blue --ignore-not-found=true

oc delete service nationalparks-green --ignore-not-found=true
oc delete service nationalparks-blue --ignore-not-found=true

oc delete service parksmap-green --ignore-not-found=true
oc delete service parksmap-blue --ignore-not-found=true

oc process -f ../templates/prodproject/stk-parks-prod-app-backend-SVC.yaml -p=DC_NAME=mlbparks-green -l app=mlbparks |oc create -f - -n ${GUID}-parks-prod
oc process -f ../templates/prodproject/stk-parks-prod-app-backend-SVC.yaml -p=DC_NAME=nationalparks-green -l app=nationalparks |oc create -f - -n ${GUID}-parks-prod
oc process -f ../templates/prodproject/stk-parks-prod-app-frontend-SVC.yaml -p=DC_NAME=parksmap-green -l app=parksmap |oc create -f - -n ${GUID}-parks-prod

oc patch route/parksmap -p '{"spec":{"to":{"name":"parksmap-green"}}}' -n ${GUID}-parks-prod
