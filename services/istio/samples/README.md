## Task 5.2:
### Instructions

Deploy the Sample app `https://istio.io/latest/docs/ambient/getting-started/deploy-sample-app/` and follow the steps until [Clean up](https://istio.io/latest/docs/ambient/getting-started/cleanup/). Note that you need to have Prometheus installed in your cluster. You most likely need to set the Prometheus URL in the file kiali.yaml as follows:
```
prometheus:
  enabled: true
  url: http://prom-prometheus-server.monitoring:80
```

### Solution

I instantly ran into issues with the Istio installation following the instrctions. When using [k3d](https://github.com/k3d-io/k3d) the cluster needs to be created with Traefik disabled so it doesn’t conflict with Istio’s ingress gateways so based on Istio's instructions I created a cluster using: `k3d cluster create --api-port 6550 -p '9080:80@loadbalancer' -p '9443:443@loadbalancer' --agents 2 --k3s-arg '--disable=traefik@server:*'`. At this point I ran into issues with ztunnel containers not getting created. [k3s](https://github.com/k3s-io/k3s/) uses nonstandard locations for CNI configurations and binaries which at least in my case weren't set correctly with only setting `values.global.platform=k3d`. I tried to install Istio with k3d configuration with the locations overridden to the k3d cluster based on the instructions with: `istioctl install --set profile=ambient --set values.global.platform=k3d --set values.cni.cniConfDir=/var/lib/rancher/k3s/agent/etc/cni/net.d --set values.cni.cniBinDir=/var/lib/rancher/k3s/data/current/bin/` but this didn't help. I then found a possibly related [GitHub issue](https://github.com/istio/istio/issues/57264) and based on that tried to install the cluster with `k3d cluster create --api-port 6550 -p '9080:80@loadbalancer' -p '9443:443@loadbalancer' --agents 2 --k3s-arg '--disable=traefik@server:*' --image rancher/k3s:v1.31.6-k3s1`. After this I was able to install Istio with `istioctl install --set profile=ambient --set values.global.platform=k3d` from the instructions without issues. Installing this way does give a warning that: `The Kubernetes version v1.31.6+k3s1 is not supported by Istio 1.31.0. The minimum supported Kubernetes version is 1.32. Proceeding with the installation, but you might experience problems. See https://istio.io/latest/docs/releases/supported-releases/ for a list of supported versions.`. I found it's possible that the Istio instructions haven't been updated to reflect the current required settings and after some digging found a [reference to a different bin path][https://docs.k3s.io/networking/multus-ipams]. After setting `values.cni.cniBinDir=/var/lib/rancher/k3s/data/cni/` the ztunnel installation was successful.

First start by installing Istio according to the instructions in the [Istio service folder](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.2/services/istio/).

#### Deploy a sample application

Deploy the bookinfo application with `kubectl apply -f bookinfo/platform/kube/bookinfo.yaml` and `kubectl apply -f bookinfo/platform/kube/bookinfo-versions.yaml`.

Deploy the sample gateway with `kubectl apply -f bookinfo/gateway-api/bookinfo-gateway.yaml`. It is assumed that the envoy gateway has been installed according to the instructions in the [service folder](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.2/services/envoy_gateway).

By default, Istio creates a LoadBalancer service for a gateway. As you will access this gateway by a tunnel, you don’t need a load balancer. Change the service type to ClusterIP by annotating the gateway: `kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default`. To check the status of the gateway, run: `kubectl get gateway`

To access the gateway, port forward with `kubectl port-forward svc/bookinfo-gateway-istio 8080:80`. The application is now available at http://localhost:8080/productpage.

#### Secure and visualize the application

All pods in a given namespace can be added to the ambient mesh by labeling the namespace. Applying `kubectl label namespace default istio.io/dataplane-mode=ambient` adds all the pods in the default namespace to the ambient mesh and secures traffic between applications.

Prometheus needs to be installed to the cluster. This can be done by following the instructions in the [prometheus folder](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.2/services/prometheus).

The application can be visualized with Kiali which uses the Prometheus metrics. Apply with `kubectl apply -f addons/kiali.yaml`. Compared to the default version of the file, the line `url: http://prom-prometheus-server.prometheus:80` was added to the prometheus configuration of the file, pointing to the Prometheus service running in the `prometheus` namespace.

The Kiali dashboard can be accessed with `istioctl dashboard kiali`.

We can send test traffic to the bookinfo application so that Kiali generates a traffic graph with the bash command `for i in $(seq 1 100); do curl -sSI -o /dev/null http://localhost:8080/productpage; done`. Clicking the Traffic Graph tab in Kiali and selecting `default` as the namespace produces a traffic graph of the Bookinfo application. Clicking a line connecting two services displays traffic metrics collected by Istio.

 Istio has created a strong identity for each service: a SPIFFE ID. This identity can be used for creating authorization policies.

 #### Enforce authorization policies

Let’s create an authorization policy that restricts which services can communicate with the productpage service. The policy is applied to pods with the `app: productpage` label, and it allows calls only from the service account `cluster.local/ns/default/sa/bookinfo-gateway-istio`. This is the service account that is used by the Bookinfo gateway you deployed in the previous step. Apply the following:

```
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: productpage-ztunnel
  namespace: default
spec:
  selector:
    matchLabels:
      app: productpage
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/bookinfo-gateway-istio
EOF
```

You should still have access at http://localhost:8080/productpage. If we apply a curl sample with `kubectl apply -f curl/curl.yaml` and try to access the service with `kubectl exec deploy/curl -- curl -s "http://productpage:9080/productpage"` the request should fail since the curl pod is using a different service account.

Next we apply a waypoint proxy with `istioctl waypoint apply --enroll-namespace --wait` to enforce layer 7 network traffic policies for traffic entering the namespace. Check with `kubectl get gtw waypoint` and ensure it has `Programmed=True` status.

Next we add a Layer 7 authorization policy that allows `curl` service to make `GET` requests to the `productpage` service by applying the following:

```
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: productpage-waypoint
  namespace: default
spec:
  targetRefs:
  - kind: Service
    group: ""
    name: productpage
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/curl
    to:
    - operation:
        methods: ["GET"]
EOF
```

The previously applied L4 policy instructed the ztunnel to only allow connections from the gateway so now need to update it to also allow connections from the waypoint. Apply the following:

```
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: productpage-ztunnel
  namespace: default
spec:
  selector:
    matchLabels:
      app: productpage
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/bookinfo-gateway-istio
        - cluster.local/ns/default/sa/waypoint
EOF
```

Trying to send a `DELETE` request from the curl service with `kubectl exec deploy/curl -- curl -s "http://productpage:9080/productpage" -X DELETE` should fail as only `GET` is allowed.

Trying to `GET` from the `deploy/reviews-v1` service with `kubectl exec deploy/reviews-v1 -- curl -s http://productpage:9080/productpage` should fail as it is not a service that is allowed by the AuthorizationPolicy.

Trying to `GET` from the `curl` service with `kubectl exec deploy/curl -- curl -s http://productpage:9080/productpage | grep -o "<title>.*</title>"` should succeed the service and request method are allowed by the AuthorizationPolicy.

#### Manage traffic

The Bookinfo application has three versions of the reviews service. You can split traffic between these versions to test new features or perform A/B testing. Apply the following configuration to route 90% of requests to reviews v1 and 10% to reviews v2:

```
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
EOF
```

To confirm that roughly 10% of the of the traffic from 100 requests goes to reviews-v2, you can run the following command: `kubectl exec deploy/curl -- sh -c "for i in \$(seq 1 100); do curl -s http://productpage:9080/productpage | grep reviews-v.-; done"`. You can see from the output that majority of requests are routed to `reviews-v1`. The same can be confirmed with refreshing http://localhost:8080/productpage: requests from the `reviews-v1` don’t have any stars, while the requests from `reviews-v2` have black stars.

#### Clean up

Remove all waypoint proxies by running `kubectl label namespace default istio.io/use-waypoint-` and `istioctl waypoint delete --all`.

Remove the namespace label that instructs Istio to include applications in the namespace to the ambient data plane with `kubectl label namespace default istio.io/dataplane-mode-`. This needs to be done before uninstalling Istio.

Delete the Bookinfo and curl deployments by running the following:

```
kubectl delete httproute reviews
kubectl delete authorizationpolicy productpage-waypoint
kubectl delete authorizationpolicy productpage-ztunnel
kubectl delete -f curl/curl.yaml
kubectl delete -f bookinfo/platform/kube/bookinfo.yaml
kubectl delete -f bookinfo/platform/kube/bookinfo-versions.yaml
kubectl delete -f bookinfo/gateway-api/bookinfo-gateway.yaml
```

Istio can be uninstalled with the following commands:

```
istioctl uninstall -y --purge
kubectl delete namespace istio-system
```