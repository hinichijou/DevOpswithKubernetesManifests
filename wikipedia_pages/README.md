## Wikipedia page application

Configuration files and Kubernetes cluster running instructions for an application that fetches the HTML content of a Wikipedia page and serves it. The source code for the script fetching the page content can be found [here](https://github.com/hinichijou/DevOpswithKubernetes/tree/5.4/wikipedia_page_fetcher)

First run a Kubernetes cluster. In chapter 5 of the course we move back to using a local cluster. For example with [k3d](https://github.com/k3d-io/k3d) you can create a cluster with `k3d cluster create -p 8081:80@loadbalancer -p 8080:81@loadbalancer --agents 2 --k3s-arg '--disable=traefik@server:*'`. Local port 8081 is opened to port 80 in load balancer. `--disable=traefik@server:*` is required for the Envoy and Istio gateway installation. If the cluster already exists it can be started with `k3d cluster start`.

The cluster uses a gateway resource to handle inter-namespace routing from a single externally exposed port to different services. Apply the infra resources using the instructions from [infrastructure folder](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.4/infrastructure). This also creates the necessary namespaces. The application uses the `wikipedia-pages` namespace.

Apply with `kubectl apply -k .`

Resources:

* [deployment_wikipedia_pages.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.4/wikipedia_pages/manifests/deployment_wikipedia_pages.yaml): Defines a deployment with the main container being a Nginx server that serves the content located at the default folder `/usr/share/nginx/html` when requested at the root path. There is an initContainer that fetches the page defined by environment variable `WIKIPEDIA_URL` when the app is deployed and saves it to a file the name of which is defined by environment variable `FILE_NAME`. There is a second initContainer with the configuration `restartPolicy: Always` which makes it a sidecar. This container activates after a random timeout defined with the environemnt variables `MIN_TIMEOUT` and `MAX_TIMEOUT` and fetches new content to replace the old by requesting `https://en.wikipedia.org/wiki/Special:Random`. The containers share an emptyDir volume to share the fetched HTML data to the main container. The saved data foes not persist between application restarts.

* [service_wikipedia_pages.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.4/wikipedia_pages/manifests/service_wikipedia_pages.yaml): defines a service for the application that uses the Nginx default port 80.

* [route_wikipedia_pages.yaml](https://github.com/hinichijou/DevOpswithKubernetesManifests/tree/5.4/wikipedia_pages/manifests/route_wikipedia_pages.yaml): defines a route resource that connects the service to the cluster Envoy gateway. There is a route rewriting rule that rewrites requests made to the gateway `/wikipedia` path to target the Nginx server root path.

After deployment application is available at: http://localhost:8081/wikipedia.

You can remove the application resources with `kubectl delete -k .`.

### Task 5.4

At first I looked into improving [task 5.1 implementation](https://github.com/hinichijou/DevOpswithKubernetes/tree/5.1/dummysite) by fetching all the page resources but Wikipedia uses some measures that actively prevents those kinds of requests. Since the task didn't have a requirement for showing the page with the additionally requested assets and they weren't required in 5.1 either I decided to settle for just fetching and serving the basic HTML content of the page.

Example logs of the sidecar running with 30-60 second random interval for testing:
```
kubectl logs -f pod/wikipedia-pages-cc4896bbb-zz6rj random-wiki-page
Wikipedia page fetcher running
Pod sleep: 49 seconds
*redacted wget output*
en.wikipedia.org/wiki/Monty_Kaser fetched and saved to file index.html

kubectl logs -f pod/wikipedia-pages-cc4896bbb-zz6rj random-wiki-page
Wikipedia page fetcher running
Pod sleep: 37 seconds
Next fetch target: en.wikipedia.org/wiki/Bodybuilding_in_Malaysia
*redacted wget output*
en.wikipedia.org/wiki/Bodybuilding_in_Malaysia fetched and saved to file index.html
```

Example page:

![Image of served page](https://github.com/hinichijou/DevOpswithKubernetesManifests/blob/5.4/task_screenshots/5-4.png?raw=true)