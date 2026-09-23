Gateway resources don't exist in a k3d cluster out of the box. To use a gateway resource in a local cluster install the [Envoy gateway](https://gateway.envoyproxy.io/) with:
```
kubectl apply --server-side -f https://github.com/envoyproxy/gateway/releases/latest/download/install.yaml

kubectl -n envoy-gateway-system rollout status deployment/envoy-gateway --timeout=180s
```

We need to define `gatewayClassName: eg` for the cluster [gateway](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/infrastructure/manifests/gateway.yaml) which isn't included in the installation. The contents can however be found from the [Envoy project GitHub repository](https://github.com/envoyproxy/gateway/blob/main/examples/kubernetes/quickstart.yaml). Apply the gatewayclass to the cluster with `kubectl apply -f manifests/gatewayclass.yaml`.