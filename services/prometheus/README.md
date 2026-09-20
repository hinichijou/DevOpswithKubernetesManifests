It is assumed that the [infrastructure folder](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.3/infrastructure) resources are applied first. This creates the necessary namespace(s).

Installs [prometheus](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus).

```
helm upgrade --install prom prometheus-community/prometheus --namespace prometheus --values prom-values.yaml
```

Apply manifests with `kubectl apply -k .`.

* [route_prometheus.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.3/services/prometheus/manifests/route_prometheus.yaml): defines the route resource for accessing the Prometheus service. The query interface will be available at `http://localhost:*application-port-here*/prometheus/query`

To use with AnalysisTemplates set `http://prom-prometheus-server.prometheus.svc.cluster.local:80` to `spec`:`metrics`:`provider`:`prometheus`:`address` field.