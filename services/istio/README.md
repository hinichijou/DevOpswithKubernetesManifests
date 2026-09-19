Uses instructions from [here](https://istio.io/latest/docs/ambient/getting-started/) and [here](https://istio.io/latest/docs/setup/additional-setup/download-istio-release/) and [here](https://istio.io/latest/docs/ambient/install/platform-prerequisites/#k3d).

Download Istio for your OS from [here](https://github.com/istio/istio/releases/tag/1.31.0) and set to path.

When using [k3d](https://github.com/k3d-io/k3d) the cluster needs to be created with Traefik disabled so it doesn’t conflict with Istio’s ingress gateways. Istio's documentation suggests `k3d cluster create --api-port 6550 -p '9080:80@loadbalancer' -p '9443:443@loadbalancer' --agents 2 --k3s-arg '--disable=traefik@server:*'`. The ports are based on the Istio documentation and could be changed to some other suitable values.

Install Istio with k3d configuration and ambient profile with `istioctl install --set profile=ambient --set values.global.platform=k3d --set values.cni.cniConfDir=/var/lib/rancher/k3s/agent/etc/cni/net.d --set values.cni.cniBinDir=/var/lib/rancher/k3s/data/cni/`. The paths are based on [k3s documentation](https://docs.k3s.io/networking/multus-ipams), the current Istio documentation contains an old bin path `/var/lib/rancher/k3s/data/current/bin/` that will cause the installation to fail.

We can now deploy the [sample application](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.2/services/istio/samples).