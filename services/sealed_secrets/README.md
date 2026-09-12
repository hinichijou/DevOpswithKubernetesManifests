Install [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) to the cluster with `kubectl apply -f https://github.com/bitnami/sealed-secrets/releases/download/v0.39.1/controller.yaml`.

Download the latest version from https://github.com/bitnami/sealed-secrets/releases and add to path.

Create a SealedSecret with `kubeseal -f source-file-name -w result-file-name`.

Note that using this approach does create the need for re-encrypting and re-commiting the sealed secret every time the local cluster is recreated since the secret can only be decrypted by the cluster.