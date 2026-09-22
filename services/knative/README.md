## Task 5.6

### Instructions

Install Knative Serving component to your k3d cluster.

For Knative to work locally in k3d you need to create it a cluster without Traefik:

```
k3d cluster create --port 8082:30080@agent:0 -p 8081:80@loadbalancer --agents 2 --k3s-arg "--disable=traefik@server:0" --image rancher/k3s:v1.34.1-k3s1
```

This command also installs Kubernetes version 1.34, which is required for the latest Knative version.

Next, follow [this](https://knative.dev/docs/install/yaml-install/serving/install-serving-with-yaml/) guide. For the network layer, you can pick Kourier. In the Configure DNS section, select Magic DNS (slip.io).

You might end up in a situation like this in the step verify the installation:
```
$ kubectl get pods -n knative-serving
NAME                                      READY   STATUS             RESTARTS      AGE
activator-67855958d-w2ws8                 0/1     Running            0             64s
autoscaler-5ff4c5d679-54l28               0/1     Running            0             64s
webhook-5446675b97-2ngh6                  0/1     CrashLoopBackOff   3 (12s ago)   64s
net-kourier-controller-58b6bf4fbc-g7dlp   0/1     CrashLoopBackOff   3 (10s ago)   55s
controller-6d8b579f9-p42dx                0/1     CrashLoopBackOff   3 (6s ago)    64s
```

See the logs of a crashing pod to see how to fix the problem.

Next, try out the examples in [Deploying a Knative Service](https://knative.dev/docs/getting-started/first-service/), [Autoscaling](https://knative.dev/docs/getting-started/first-autoscale/) and [Traffic splitting](https://knative.dev/docs/getting-started/first-traffic-split/).

Note you can access the service from the host machine as follows:
```
curl -H "Host: hello.default.192.168.240.3.sslip.io" http://localhost:8081
```

Where Host is the URL you get with the following command:
```
kubectl get ksvc
```

### Solution steps

Since the version pulled on k3d cluster create with default settings is v1.35.5-k3s1 I created the cluster with the command `k3d cluster create --port 8082:30080@agent:0 -p 8081:80@loadbalancer --agents 2 --k3s-arg "--disable=traefik@server:0"`

`kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.23.0/serving-crds.yaml` installs the required custom resources.

`kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.23.0/serving-core.yaml` installs the core components of Knative Serving.

Knative Kourier controller can be installed with `kubectl apply -f https://github.com/knative-extensions/net-kourier/releases/download/knative-v1.23.0/kourier.yaml`.

The following Bash command configures Knative Serving to use Kourier by default:
```
kubectl patch configmap/config-network --namespace knative-serving --type merge --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'
```

Get the external IP address (FQDN) to later configure DNS with `kubectl --namespace kourier-system get service kourier`.


Monitor the Knative components until all of the components show a STATUS of Running or Completed. You can do this by running the following command and inspecting the output: `kubectl get pods -n knative-serving`.

Knative provides a Kubernetes Job called default-domain that configures Knative Serving to use sslip.io as the default DNS suffix: `kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.23.0/serving-default-domain.yaml`.

This configuration works only if the cluster LoadBalancer Service exposes an IPv4 address or hostname. It does not work with IPv6 clusters or local setups such as minikube unless the minikube tunnel is running.

I did not run into issues with crashing pods at this point:

![Image of the knative pods](https://github.com/hinichijou/DevOpswithKubernetesManifests/blob/5.6/task_screenshots/5-6.png?raw=true)

#### Deploying a Knative Service

Deploy the Service by running the Bash command:
```
kubectl apply -f - <<EOF
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: hello
spec:
  template:
    spec:
      containers:
        - image: ghcr.io/knative/helloworld-go:latest
          ports:
            - containerPort: 8080
          env:
            - name: TARGET
              value: "World"
EOF
```

Expcted output: `service.serving.knative.dev/hello created`.

#### Autoscaling

A Knative Service by default scales down to zero running pods when it is not in use.

View the URL where your Knative Service is hosted with `kubectl get ksvc`.

The Knative Service can be accessed with `curl -H "Host: *service-url*" http://localhost:8081` instead of using the command from the Knative example.

Watch the pods and see how they scale to zero after traffic stops going to the URL with `kubectl get pod -l serving.knative.dev/service=hello -w`. It may take up to 2 minutes for the pods to scale down.

#### Traffic splitting

Instead of TARGET=World, update the environment variable TARGET on your Knative Service to greet "Knative" instead.

```
kubectl apply -f - <<EOF
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: hello
spec:
  template:
    spec:
      containers:
        - image: ghcr.io/knative/helloworld-go:latest
          ports:
            - containerPort: 8080
          env:
            - name: TARGET
              value: "Knative"
EOF
```

Because you are updating an existing Knative Service, the URL won't change, but the new Revision has the new name hello-00002.

If we curl now with `curl -H "Host: *service-url*" http://localhost:8081` we can see the changed message.

Existing revisions can be listed with `kubectl get revisions`.  How the traffic is split between the revisions is also displayed if using the knative CLI command `kn revisions list`. The default behavior is directing 100% of traffic to the latest revision.

Split the traffic between the two Revisions by applying:

```
kubectl apply -f - <<EOF
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: hello
spec:
  template:
    spec:
      containers:
        - image: ghcr.io/knative/helloworld-go:latest
          ports:
            - containerPort: 8080
          env:
            - name: TARGET
              value: "Knative"
  traffic:
  - latestRevision: true
    percent: 50
  - latestRevision: false
    percent: 50
    revisionName: hello-00001
EOF
```

`kn revisions list` can be used to verify the traffic split. Also curling the service multiple times with `curl -H "Host: *service-url*" http://localhost:8081` shows how the traffic is split between services.