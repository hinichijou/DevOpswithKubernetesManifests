## Deployment pipeline

Workflow triggered on workflow dispatch that modifies the `kustomization.yaml` with the latest image tags and then commits the `kustomization.yaml`.

[push_image_changes_on_dispatch.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/main/.github/workflows/push_image_changes_on_dispatch.yaml) defines the GitHub workflow. The workflow is triggered by the [source code repository](https://github.com/hinichijou/DevOpswithKubernetes/tree/main/.github/workflows/) that builds the application images. The workflow edits the `kustomization.yaml` of todo_app and/or log output ping-pong application and commits and tags the changes if necessary.

Argo CD can be configured to watch for changes to the application manifests and any changes to a specific `kustomization.yaml` or the manifests it refers to will trigger a new deployment of the application to a local cluster.

Inputs:

* `environment`: not required, basically expected to be `staging` or `production`. If empty will be treated as staging.
* `tag`: not required, if the pipeline is triggered by tagging the source code repo is expected to be the same as the tag triggering the workflow. If empty the manifest update commit will not be tagged. Only todo app commits are tagged as the tag workflow was only required for the project.
* `_image` suffixed variables: not required explicitly, but all variables for a given application should be set to update the application manifest images. Expected to be in the format: `IMAGE_ALIAS_IN_MANIFEST=DOCKERHUB_NAMESPACE/IMAGE_NAME-ENVIRONMENT@sha` for todo app images and `IMAGE_ALIAS_IN_MANIFEST=DOCKERHUB_NAMESPACE/IMAGE_NAME@sha` for log output ping-pong application images.