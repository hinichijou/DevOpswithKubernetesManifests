## Monitoring setup

Monitoring stack using Prometheus, Loki, Alloy (k8s-monitoring) and Grafana.

Install [Helm](https://helm.sh/docs/intro/install/).

Register repositories for Prometheus and Grafana to Helm:
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

Run a Kubernetes cluster if you aren't running one already. For example with k3d you can run `k3d cluster create -p 8081:80@loadbalancer --agents 2`. Local port 8081 is opened to port 80 in load balancer.

Create a namespace for the monitoring resources with `kubectl create namespace monitoring`.

The [`values folder`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/monitoring/values) contains configuration files for each of the components.

Install the monitoring components by running the following in the values folder. The dependency order needs to be followed: Alloy needs Loki running and Grafana needs both Prometheus and Loki available:
```
helm upgrade --install prom prometheus-community/prometheus \
  --namespace monitoring \
  --create-namespace \
  --values prom-values.yaml

helm upgrade --install loki grafana/loki \
  --namespace monitoring \
  --values loki-values.yaml

helm upgrade --install k8smon grafana/k8s-monitoring \
  --namespace monitoring \
  --values k8smon-values.yaml

helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --values grafana-values.yaml
```

You can use the following commands to confirm everything is running correctly:
```
helm list --namespace monitoring
kubectl get svc --namespace monitoring
kubectl get pods --namespace monitoring
```

You can port forward Grafana to localhost port 3000 with `kubectl port-forward --namespace monitoring svc/grafana 3000:80`. The monitoring UI should now be available at http://localhost:3000. Use the default credentials admin/admin to log in.

You can for example query log messages by namespace by setting Loki as datasource and making the query `{namespace="default"}`.

You can remove almost anything with `helm delete [name]` with the name found using the command `helm list --namespace monitoring`. Custom resource definitions are left and have to be manually removed if the need arises. The definitions don't do anything by themselves, so leaving them does no harm.

The cluster can be stopped with `k3d cluster stop` and started with `k3d cluster start`. The cluster can be deleted with `k3d cluster delete`.