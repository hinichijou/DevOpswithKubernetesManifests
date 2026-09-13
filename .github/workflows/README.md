## Deployment pipeline

Configuration for a pipeline that builds docker images, modifies the `kustomization.yaml` with the new image tags and then commits the `kustomization.yaml`.

It makes sense to build and upload only the images if there are changes to the related files. For that reason to workflow checks if there are changes to the related folder before triggering the build step. There is a popular GitHub Action [dorny/paths-filter](https://github.com/dorny/paths-filter) that seems to be built just for this purpose so this can be leveraged in our workflow to get a neat solution for monitoring changes in certain folders. If there are no changes to the folder relevant for the image the workflow will search for the latest image built from the branch and uses that.

Uses the repository secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` which contain the dockerhub username and the access token created for accessing the dockerhub repository.

[build-deploy-on-push.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/main/.github/workflows/build-deploy-on-push.yaml) defines the GitHub workflow. The workflow follows changes to the log output ping-pong application related folders and todo app related folders and builds the related images and commits the app `kustomization.yaml` if necessary.

Uses custom actions [build image](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/main/.github/actions/build_image/action.yaml) which builds the image, pushes it to a repository and adds the image tag to the `kustomization.yaml` and [fetch image](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/main/.github/actions/fetch_image/action.yaml) which tries to fetch an existing image from the Docker repository, and if the fetch fails builds a new image with the build image action.

Argo CD can be configured to watch for changes to the application manifests and any changes to a specific `kustomization.yaml` or the manifests it refers to will trigger a new deployment of the application to a local cluster.

### Task 4.9

Since the project app now supports separate staging and production environments while the exercises app does not the build logic and image naming schemes slightly differ.

* The log output ping-pong app watches for pushes to certain folders to determine which images need to be built. The images are named: *image-name*:*commit-sha*. Built only on push to main branch.

* The todo app staging watches for pushes to certain folders to determine which images need to be built. The images are named: *image-name*-staging:*commit-sha*. Staging images are built only on push to main branch.

* The todo app production images are built on every tag. The images are named: *image-name*-production:*tag-name*. Production images are built only on tag trigger.