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

#config permission
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-dev

oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-dev

oc policy add-role-to-user edit system:serviceaccount:gpte-jenkins:jenkins -n ${GUID}-parks-dev

oc policy add-role-to-user admin system:serviceaccount:gpte-jenkins:jenkins -n ${GUID}-parks-dev

#create buildconfig
oc new-build --binary=true --name="MLBParks" jboss-eap70-openshift:1.7 -n ${GUID}-parks-dev

oc new-build --binary=true --name="NationalParks" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev

oc new-build --binary=true --name="ParksMap" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev

#create configmap
oc create configmap MLBParks-config --from-file=./Infrastructure/templates/MLBParks-dev.properties -n ${GUID}-parks-dev

oc create configmap NationalParks-config --from-file=./Infrastructure/templates/NationalParks-dev.properties -n ${GUID}-parks-dev

oc create configmap ParksMap-config --from-file=./Infrastructure/templates/ParksMap-dev.properties -n ${GUID}-parks-dev

#create app
oc new-app ${GUID}-parks-dev/MLBParks:0.0-0 --name=MLBParks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev

oc new-app ${GUID}-parks-dev/NationalParks:0.0-0 --name=NationalParks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev

oc new-app ${GUID}-parks-dev/ParksMap:0.0-0 --name=ParksMap --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev

#remove triggers
oc set triggers dc/MLBParks --remove-all -n ${GUID}-parks-dev

oc set triggers dc/NationalParks --remove-all -n ${GUID}-parks-dev

oc set triggers dc/ParksMap --remove-all -n ${GUID}-parks-dev

#set ent for dc
oc set env dc/MLBParks --from=configmap/MLBParks-config -n ${GUID}-parks-dev

oc set env dc/NationalParks --from=configmap/NationalParks-config -n ${GUID}-parks-dev

oc set env dc/ParksMap --from=configmap/ParksMap-config -n ${GUID}-parks-dev

oc set probe dc/ParksMap --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-dev
oc set probe dc/ParksMap --readiness --failure-threshold 5 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

oc set probe dc/MLBParks --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-dev
oc set probe dc/MLBParks --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

oc set probe dc/NationalParks --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-dev
oc set probe dc/NationalParks --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

#expose svcs
oc expose dc MLBParks --port 8080 -n ${GUID}-parks-dev

oc expose dc NationalParks --port 8080 -n ${GUID}-parks-dev

oc expose dc ParksMap --port 8080 -n ${GUID}-parks-dev

oc expose svc MLBParks -n ${GUID}-parks-dev --labels="type=parksmap-backend"

oc expose svc NationalParks -n ${GUID}-parks-dev --labels="type=parksmap-backend"

oc expose svc ParksMap -n ${GUID}-parks-dev

