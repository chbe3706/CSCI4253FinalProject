#!/bin/sh
## Set the project and zone
gcloud config set project firm-amp-292119
gcloud config set compute/zone us-central1-b

# Create preemtible mykube cluster
gcloud container clusters create --preemptible mykube
# Allow for load balancing on the cluster
gcloud container clusters update mykube --update-addons=HttpLoadBalancing=ENABLED --enable-stackdriver-kubernetes

## Set redis, and rabbitMQ files and port-forward 
# You can use this script to launch Redis and RabbitMQ on Kubernetes
# and forward their connections to your local computer. That means
# you can then work on your worker-server.py and rest-server.py
# on your local computer rather than pushing to Kubernetes with each change.
#
# To kill the port-forward processes us e.g. "ps augxww | grep port-forward"
# to identify the processes ids
kubectl apply -f redis/redis-deployment.yaml
kubectl apply -f redis/redis-service.yaml
kubectl apply -f rabbitmq/rabbitmq-deployment.yaml
kubectl apply -f rabbitmq/rabbitmq-service.yaml

kubectl wait pod --for=condition=ready --all --timeout 10m

# must background to continue through port forwarding
kubectl port-forward --address 0.0.0.0 service/rabbitmq 5672:5672 &
kubectl port-forward --address 0.0.0.0 service/redis 6379:6379 &

# apply the rest yamls
kubectl apply -f rest/rest-deployment.yaml &&
kubectl apply -f rest/rest-service.yaml &&

# apply the logs yaml
kubectl apply -f rest/logs-deployment.yaml &&

# apply the logs yaml
kubectl apply -f worker/worker-deployment.yaml &&

# apply ingress
kubectl apply -f rest/rest-ingress.yaml &&

# print ingress details
kubectl describe ingress my-ingress

# kubectl port-forward svc/prometheus 9090:9090 -n monitoring &
# kubectl --namespace monitoring port-forward svc/grafana 3000 &