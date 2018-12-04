projects=$(oc get projects --output=jsonpath={.items..metadata.name})
for project in $projects; do
    echo "exporting project $project"
    oc export deploymentconfigs,routes,svc,pvc,buildconfigs,secrets,configmap --as-template=$project -n $project > $project.yaml
done
