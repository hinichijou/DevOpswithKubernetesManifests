It is assumed that the [infrastructure folder](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/main/infrastructure) resources are applied first. This creates the necessary namespace(s).

Install [NATS](https://docs.nats.io/) to the cluster with:
```
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm repo update
helm upgrade --install my-nats nats/nats --namespace nats --set promExporter.enabled=true
```