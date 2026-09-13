It is assumed that the [infrastructure folder](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/main/infrastructure) resources are applied first. This creates the necessary namespace(s).

Installs the [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack).

The course material example is installed with a randomized name which works for temporary testing environments:
```
helm install prometheus-community/kube-prometheus-stack --generate-name --namespace prometheus
```

To use with AnalysisTemplates first find the DNS name for the prometheus service with `kubectl get svc -n prometheus` which looks like `kube-prometheus-stack-*this number changes*-prometheus`.

To install with a persisting service name `prom-kube-prometheus-stack-prometheus` instead install with:
```
helm upgrade --install prom prometheus-community/kube-prometheus-stack --namespace prometheus
```

The service address will need to be set to AnalysisTemplate `spec`:`metrics`:`provider`:`prometheus`:`address` field.

Apply manifests with `kubectl apply -k .`.

* [route_prometheus.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/main/services/kube-prometheus-stack/manifests/route_prometheus.yaml): defines the route resource for accessing the Prometheus service. The query interface will be available at `http://localhost:*application-port-here*/prometheus/query`