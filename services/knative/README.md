When using [k3d](https://github.com/k3d-io/k3d) the cluster needs to be created with Traefik disabled The cluster can be created with `--k3s-arg '--disable=traefik@server:*'`.

Install required custom resources with `kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.23.0/serving-crds.yaml`.

Install the core components of Knative Serving with `kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.23.0/serving-core.yaml`.

Knative supports [multiple ingress providers](https://knative.dev/docs/install/yaml-install/serving/install-serving-with-yaml/#install-a-networking-layer) like Kourier and Istio. Follow the instructions behind the link to install one of the options.

Monitor the Knative components until all of the components show a STATUS of Running or Completed. You can do this by running the following command and inspecting the output: `kubectl get pods -n knative-serving`.

Knative also supports [multiple DNS configurations](https://knative.dev/docs/install/yaml-install/serving/install-serving-with-yaml/#configure-dns).