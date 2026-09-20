Uses instructions from [here](https://istio.io/latest/docs/ambient/getting-started/) and [here](https://istio.io/latest/docs/setup/additional-setup/download-istio-release/) and [here](https://istio.io/latest/docs/ambient/install/platform-prerequisites/#k3d).

Download Istio for your OS from [here](https://github.com/istio/istio/releases/tag/1.31.0) and set to path.

When using [k3d](https://github.com/k3d-io/k3d) the cluster needs to be created with Traefik disabled so it doesn’t conflict with Istio’s ingress gateways. The cluster should be created with `--k3s-arg '--disable=traefik@server:*'`.

Install Istio with k3d configuration and ambient profile with `istioctl install --set profile=ambient --set values.global.platform=k3d --set values.cni.cniConfDir=/var/lib/rancher/k3s/agent/etc/cni/net.d --set values.cni.cniBinDir=/var/lib/rancher/k3s/data/cni/`. The paths are based on [k3s documentation](https://docs.k3s.io/networking/multus-ipams), the current Istio documentation contains an old bin path `/var/lib/rancher/k3s/data/current/bin/` that will cause the installation to fail.

You can enable all pods in a given namespace to be part of an ambient mesh by labeling the namespace with `kubectl label namespace *namespace-name* istio.io/dataplane-mode=ambient`.

If using L7 routing and authorization features the namespace needs to be created a waypoint proxy by applying `istioctl waypoint apply --enroll-namespace --wait` to the namespace. Check with `kubectl get gtw waypoint` that the waypoint proxy has `Programmed=True` status.

The application can be visualized with Kiali using the Prometheus metrics. Apply with `kubectl apply -f manifests/kiali.yaml`. Compared to the default version of the file, the line `url: *url-of-the-prometheus-server-here*` should be added to the prometheus configuration of the file, pointing to the Prometheus service running in the `prometheus` namespace. If using the [base prometheus installation](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.3/services/prometheus) this would be `http://prom-prometheus-server.prometheus.svc.cluster.local:80`.

You can access Kiali with `istioctl dashboard kiali`.