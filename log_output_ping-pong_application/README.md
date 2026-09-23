## Log output and ping-pong applications

Configuration files and Kubernetes cluster running instructions for the application. The source code for the application can be found [here](https://github.com/hinichijou/DevOpswithKubernetes/tree/5.7/log_output_ping-pong_application)

First run a Kubernetes cluster. In chapter 5 of the course we moved back to using a local cluster. For example with [k3d](https://github.com/k3d-io/k3d) you can create a cluster with `k3d cluster create -p 8081:80@loadbalancer -p 8080:81@loadbalancer --agents 2 --k3s-arg '--disable=traefik@server:*'`. Local port 8081 is opened to port 80 in load balancer and port 8080 to port 81. `--disable=traefik@server:*` is required for the gateway api installation. If the cluster already exists it can be started with `k3d cluster start`.

Check with `kubectl cluster-info` that your configuration is pointing to the local cluster. If it is not we can correct this by running `kubectl config get-contexts` to get the name of the context and set it with `kubectl config use-context *context-name*`.

The gateway resource handles inter-namespace routing from a single externally exposed port to different services. Apply the infra resources using the instructions from [infrastructure folder](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/infrastructure). This also creates the necessary namespaces and persistent volumes.

After Istio is installed and the exercises namespace is created in the previous step you should label the namespace to use a service mesh with `kubectl label namespace exercises istio.io/dataplane-mode=ambient` and create a waypoint proxy by applying `istioctl waypoint apply --enroll-namespace --wait` to the namespace.

The application uses SealedSecrets to decrypt sensitive files inside the cluster. Install with the instructions in the [sealed_secrets folder](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/services/sealed_secrets). If the cluster was just created [`sealed_secret_postgres.yaml`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/sealed_secret_postgres.yaml) should be re-encrypted and re-pushed to the repository as it can only be decrypted by the cluster that sealed it.

The application uses Knative which should be installed according to instructions in the [Knative service folder](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/services/knative). See more in [this section](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.3/log_output_ping-pong_application#task-57).

To automate the deployment Argo CD can be added to the cluster using the instructions from [argocd service folder](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/services/argocd).

Deploy with `kubectl apply -k .`. This creates the resources defined by the yamls listed in [`kustomization.yaml`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/kustomization.yaml) resources. The services connect the application port to a cluster internal network port. The route resources define how the cluster internal services match to routing paths while the gateway resource defines a point of access to the cluster at which traffic is routed. The ping-pong application and the log output reader have externally exposed routes while the postgres database is not exposed externally. [`The ping-pong application route`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/route_ping_pong.yaml) defines a route rewriting rule where requests to the `/pingpongs` path are routed to the root path of the ping-pong application. Also the `hostname` is applied in the rewriting rule so that routing to the Knative service works.

[`manifests/persistentvolumeclaim_log_output.yaml`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/persistentvolumeclaim_log_output.yaml) requests a persistent volume resource to be used by the log output reader and writer, the data written persists between application runs. The log output writer and reader share a deployment. The log output writer writes a log which the reader reads and outputs. [`manifests/configmap_log_output.yaml`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/configmap_log_output.yaml) holds the environment variables for the log output runner and the configMapGenerator in [`kustomization.yaml`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/kustomization.yaml) creates a file resource for the log output runner to use based on the contents of [`assets/information.txt`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/assets/information.txt) if available at deployment time.

[knative_service_ping_pong.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/knative_service_ping_pong.yaml) defines a Knative service for the ping-pong application.

The ping-pong application saves the ping counter to a Postgres database with persistent storage which is run as a single replica StatefulSet defined in [`statefulset_postgres.yaml`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/statefulset_postgres.yaml). The env values required for the configuration of the database can be found in [`configmap_postgres.yaml`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/configmap_postgres.yaml). The setup also expects a secret file  `secret_postgres.yaml` which is not in version control which has the name `secret-postgres-config` and defines the environment variable `POSTGRES_PASSWORD`. You can refer to the encrypted version of the file [`sealed_secret_postgres.yaml`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/sealed_secret_postgres.yaml) to see what kind of resource is expected.

[deployment_greeter.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/deployment_greeter.yaml) defines deployments for two different versions of the greeter which return a different message when they receive a request to the root path. [service_greeter.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/service_greeter.yaml) defines two services for the two different greeter versions and a third "main" service that is used to route traffic to the different versions based on the routing rule defined in [route_greeter.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/route_greeter.yaml). The routing configuration works only if the namespace is using an Istio waypoint proxy.

Follow output logs with `kubectl logs -f *insert pod name here*`. You can use `kubectl get pods` to find out the pod name.

A random string generated on application start and a time stamp is written to a log file every 5 seconds. The endpoint `http://localhost:8081/pingpong` displays a counter showing how many requests to the endpoint have been made while the application is running. The `http://localhost:8081` endpoint shows the last log output row and the counter for the ping-pong application. The counter value is fetched from the cluster internal endpoint set to environment variable `PING_PONG_APP_URL`. Similarly the message returned from the cluster internal endpoint set to environment variable `GREETER_APP_URL` is displayed. Also the defined value of the environment variable `MESSAGE` (see [`manifests/configmap_log_output.yaml`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/configmap_log_output.yaml) and how the env variables are defined in [`manifests/deployment_log_output.yaml`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/deployment_log_output.yaml)) and the contents of the `information.txt` file (see [`kustomization.yaml`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/kustomization.yaml) configMapGenerator and how the volume is defined in [`manifests/deployment_log_output.yaml`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/deployment_log_output.yaml)) are displayed if available. The ping-pong application, the log output writer application and the greeter all have a health check path `/health` and readiness check path `/ready`. [deployment_log_output.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/deployment_log_output.yaml), [knative_service_ping_pong.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/knative_service_ping_pong.yaml) and [deployment_greeter.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/deployment_greeter.yaml) all define a LivenessProbe and a ReadinessProbe for the containers.

[push_image_changes_on_dispatch.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/.github/workflows/push_image_changes_on_dispatch.yaml) defines a GitHub workflow triggered by the source code repository for updating the correct images to kustomization files. The image changes are committed to the repository which the Argo CD setup follows and deploys. [See readme](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/.github/workflows/README.md) for more detailed description.

You can remove the application resources with `kubectl delete -k .` and the persistent volume claims with `kubectl delete -f persistent_volume_manifests`. This doesn't delete the postgres persistent volumes which are not directly created by the manifests. You can delete them by finding the names with `kubectl get pvc` and calling delete directly for the persistent volume claims. You can also delete all resources of certain type, for example `kubectl delete --all deployments` would delete all deployment resources in the current namespace. Deleting the whole namespace with `kubectl delete namespace exercise` will also delete all the resources in the namespace. If using Argo CD for deployment the Argo CD application deletion also deletes deployment related resources.

Because the `log-output-pv` PersistentVolume gets claimed by a specific `log-output-claim` PersistentVolumeClaim deployment, if you remove the resources but want to use the same persistent volume to keep the data stored for a new deployment you should delete the `claimRef` entry from PV specs, so as new PVC can bind to it. This should make the PV Available. This can be done with bash command `kubectl patch pv log-output-pv -p '{"spec":{"claimRef": null}}'`.

The cluster can be stopped with `k3d cluster stop` and started with `k3d cluster start`. The cluster can be deleted with `k3d cluster delete`.

### Task 5.7

#### Instructions
Make the Ping-pong service of the Log Output app use serverless.

Reading [this](https://knative.dev/docs/serving/convert-deployment-to-knative-service/) might be helpful.

TIPS:

* Use the fully qualified Kubernetes service DNS name when calling services. So instead of, e.g., http://pingpong, you must use http://pingpong.exercises.svc.cluster.local. This avoids host-routing issues in the Knative setup and ensures requests resolve correctly inside the cluster.

* You could set the hostname in the url rewrite role to make the pigpong endpoint accessibe also from the browser:
```
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /pingpong
      filters:
        - type: URLRewrite
          urlRewrite:
            hostname: pingpong.exercises.192.168.144.3.sslip.io
            path:
              type: ReplacePrefixMatch
              replacePrefixMatch: /
```

#### Solution

Based on [Converting a Kubernetes Deployment to a Knative Service](https://knative.dev/docs/serving/convert-deployment-to-knative-service/) the ping-pong app itself is a good fit for knative service: work is triggered by HTTP, state is saved to the postgres database and there are no volumes used outside of Secrets and ConfigMaps. The conversion means that the [deployment](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.6/log_output_ping-pong_application/manifests/deployment_ping_pong.yaml) and [service](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.6/log_output_ping-pong_application/manifests/service_ping_pong.yaml) files will be converted to a single Knative Service.

Since the app is already using Istio I thought I'd use it as the Ingress provider for Knative. After reading about the [Istio installation](https://knative.dev/docs/install/yaml-install/serving/install-serving-with-yaml/#__tabbed_1_3) and Knative networking configuration it seemed to make the most sense to use the Knative Istio installation instead of using the standalone Istio installation. However the Knative Istio installation isn't using the ambient profile and doesn't seem to [support the ambient mode](https://github.com/knative-extensions/net-istio/issues/1360). There were quite good istructions on creating own gateways and overriding configurations but while I got it to work to a certain extent there is a fundamental issue with the knative configuration expecting a Istio API ingress gateway resource which is used for external access and the DNS didn't work when routing the traffic from a gateway.networking.k8s.io/v1 gateway resource used this far. The process seemed a lot more complex than the examples in the material which made me think that the point of the task was probably to slap the Kourier provider on top of the current Istio setup but I didn't like the idea of separate external access points for different services. I then decided to look into the [Gateway API implementation](https://knative.dev/docs/install/yaml-install/serving/install-serving-with-yaml/#__tabbed_1_4) since we already have the Gateway API gateway in place. While the component is in beta it is supported and I thought it probably works well enough for the purposes of this task.

The instructions for setting up the cluster in this readme should be followed until the step where Sealed Secrets are installed. In this task Argo Rollouts was removed as a component because of its overlapping features with Knative which means that Prometheus was also removed as a component since the analysistemplate is no longer used. Because Knative used port 80 for traffic routing by default I changed the gateway that log output ping-pong application uses to use port 80 which means that the application is available at localhost:8081 instead of localhost:8080 as in the previous task.

After setting up the cluster Knative should be installed according to the instructions in the [Knative service folder](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/services/knative).

Knative Gateway API is installed with `kubectl apply -f https://github.com/knative-extensions/net-gateway-api/releases/download/knative-v1.23.0/net-gateway-api.yaml`.

The following configures Gateway resources for external ("north-south") and local ("east-west") Knative traffic. If you do not need separate routing for local traffic (or private Knative services), you can use the external Gateway for both. File syntax is based on [this](https://github.com/knative-extensions/net-gateway-api/blob/main/config/config-gateway.yaml), the current version of the Knative.dev instructions have old incompatible syntax.
```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-gateway
  namespace: knative-serving
data:
  external-gateways: |
    - class: istio
      gateway: infra/infra-istio-gateway  # Name of the external Gateway resource
      service: infra/infra-istio-gateway-istio  # backing Service FQDN
  local-gateways: |
    - class: istio
      gateway: infra/infra-istio-gateway    # Name of the local Gateway resource
      service: infra/infra-istio-gateway-istio   # backing Service FQDN
EOF
```

Configure Knative Serving to use the Knative Gateway API ingress class:
```
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"gateway-api.ingress.networking.knative.dev"}}'
```

It seems that applying the serving-default-domain.yaml from the Knative instructions doesn't work with the Gateway API but [these instructions](https://knative.dev/blog/articles/set-up-a-local-knative-environment-with-kind/#step-3-set-up-networking-using-kourier) show how it can be applied manually with:

```
kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"127.0.0.1.sslip.io":""}}'
```

[`The ping-pong application route`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/route_ping_pong.yaml) sets a hostname in a URLRewrite filter according to the course material instructions so that the knative service can be accessed from the browser. [`The log output app config map`](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/configmap_log_output.yaml) refers to the ping pong application service with the fully qualified service DNS name as in the instructions so that the requests are correctly routed. The Knative service version of the ping-pong service is defined in [knative_service_ping_pong.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/log_output_ping-pong_application/manifests/knative_service_ping_pong.yaml).

Kiali produces the following traffic graph:

![Image of the setup in Kiali](https://github.com/hinichijou/DevOpswithKubernetesManifests/blob/5.7/task_screenshots/5-7.png?raw=true)