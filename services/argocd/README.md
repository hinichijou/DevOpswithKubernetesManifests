It is assumed that the [infrastructure folder](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.3/infrastructure) resources are applied first. This creates the necessary namespace(s).

Install [ArgoCD](https://argo-cd.readthedocs.io/en/stable/getting_started/) with the following command(s):
```
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Apply manifests with `kubectl apply -k .`.

* [route_argocd.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/services/argocd/manifests/route_argocd.yaml): defines the route resource for accessing the ArgoCD service that is used for managing application deployments.
* [configmap_argocd.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/services/argocd/manifests/configmap_argocd.yaml): see [instructions](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#gateway-api-example). Uses `server.insecure: "true"` to allow http traffic, for remote use this could be ok also but we would need to enforce https on gateway level in that case. Other option would be to enforce https on gateway level and use self-signed certificates for local testing. Exposing with a LoadBalancer instead would allow a direct https connection from the browser.

After applying the configmap changes you may have to restart the ArgoCD server with `kubectl rollout restart deployment.apps/argocd-server -n argocd` for the changes to be applied. Because of browser caching you may have to clear the browser cookies.

[Applications folder](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/services/argocd/applications/applicationset_todo_app.yaml) holds application manifests that need to be applied for applications that have Argo CD app configuration manifests.

* Apply todo app application manifest with `kubectl apply -f applications/applicationset_todo_app.yaml`, delete with `kubectl delete -f applications/applicationset_todo_app.yaml`.

The Argo CD service can be accessed at http://localhost:8081/argocd.

The admin account password can be found by base64 decoding the password from: `kubectl get -n argocd secrets argocd-initial-admin-secret -o yaml`.

When manually adding an application give the app a name, use the project `default`, and leave the sync policy as Manual. For Destination, set cluster URL to `https://kubernetes.default.svc` (or `in-cluster` for cluster name) and namespace to `default`. Connect the repo to Argo CD by setting source repository url to the github repo url and leave the revision as HEAD, and set path to match the application folder. After a manual sync, set the sync to automatic from the app page details view (alternatively set the sync policy straight to automatic under the project name field when creating).