## Deployment pipeline

Workflow triggered on workflow dispatch that modifies the `kustomization.yaml` with the latest image tags and then commits the `kustomization.yaml`.

[push_image_changes_on_dispatch.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/main/.github/workflows/push_image_changes_on_dispatch.yaml) defines the GitHub workflow. The workflow is triggered by the [source code repository](https://github.com/hinichijou/DevOpswithKubernetes/tree/main/.github/workflows/) that builds the application images. The workflow edits the `kustomization.yaml` of todo_app and/or log output ping-pong application and commits and tags the changes if necessary.

Argo CD can be configured to watch for changes to the application manifests and any changes to a specific `kustomization.yaml` or the manifests it refers to will trigger a new deployment of the application to a local cluster.

Since the project app supports separate staging and production environments while the log_ouput_ping-pong_application does not the build logic and image naming schemes slightly differ.

* The log output ping-pong app: the images are named: *image-name*:*commit-sha*. Built only on push to the source code repository main branch if there are changes to relevant files.

* The todo app staging: the images are named: *image-name*-staging:*commit-sha*. Staging images are built only on push to the source code repository main branch if there are changes to relevant files.

* The todo app production: the images are named: *image-name*-production:*tag-name*. Production images are built only when source code repository gets pushed a tag.