#!/bin/sh

# unset kubeconfig so gcloud generates new in $HOME/.kube
unset KUBE_CONFIG

PROJECT_NAME=fabijanbajo
CLUSTER_NAME=fabijanbajo
REGION=us-central1
ZONE=${REGION}-a
MACHINE_TYPE=g1-small
NODE_COUNT="2"

gcloud container clusters create "fabijanbajo" \
  --project $PROJECT_NAME \
  --zone $ZONE \
  --no-enable-basic-auth \
  --cluster-version "1.13.6-gke.13" \
  --machine-type "g1-small" \
  --image-type "COS" \
  --disk-type "pd-standard" \
  --disk-size "10" \
  --metadata disable-legacy-endpoints=true \
  --scopes "https://www.googleapis.com/auth/cloud-platform" \
  --preemptible \
  --num-nodes $NODE_COUNT \
  --enable-ip-alias \
  --network "projects/${PROJECT_NAME}/global/networks/default" \
  --subnetwork "projects/${PROJECT_NAME}/regions/${REGION}/subnetworks/default" \
  --default-max-pods-per-node "110" \
  --addons HorizontalPodAutoscaling \
  --enable-autoupgrade \
  --enable-autorepair \
  --no-enable-cloud-logging \
  --no-enable-cloud-monitoring \
  --maintenance-window "22:00"
