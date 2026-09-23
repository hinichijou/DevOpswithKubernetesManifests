It is assumed that the [infrastructure folder](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.7/infrastructure) resources are applied first. This creates the necessary namespace(s).

To use the rollout and analysis template resources in the project we need to install [Argo Rollouts](https://argoproj.github.io/argo-rollouts/architecture/#rollout-resource):
```
kubectl apply --server-side -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

After deploying the application the rollout can be visualized with `kubectl argo rollouts get rollout rollout-name --watch`. To be able to use the command you will first need to install the argo rollouts kubectl plugin using [these instructions](https://argoproj.github.io/argo-rollouts/installation/#kubectl-plugin-installation). `kubectl get analysisrun` and `kubectl describe analysisrun` can be used to view the measured values of the analysisrun defined by the analysis template.

Note that when the resource is deployed for the first time all of the pods are created instantly, the defined canary strategy will apply when the rollout resource is updated. Specifically changes to spec.template field will trigger a new rollout.