# Local kind dev cluster

This project provides a local **Kubernetes development cluster**.
It should **never** be used in a production environment. Its sole purpose is to provide a quick and easy **local Kubernetes playground**.

The cluster is based on [kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker) and comes pre-configured with some useful apps:

* [ingress-nginx](https://github.com/kubernetes/ingress-nginx)
* [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
* [Argo Workflows](https://argoproj.github.io/workflows/)

Additionally, the setup includes a **Docker Registry Proxy**, which caches container images locally. This can significantly speed up image pulls/cluster startup and reduce external network usage.


## Requirements

You must have installed the following CLI tools:

* [Docker](https://docs.docker.com/engine/install/)
* [kind](https://kind.sigs.k8s.io/)
* [helm](https://helm.sh/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/)

If you want to use argo, it also makes sense to install the [argo CLI tool](https://argo-workflows.readthedocs.io/en/latest/walk-through/argo-cli/)


## Usage

1. Run the main setup script:

```bash
./kind.sh
```

Be patient and wait until the script finishes. It will:

* Start the Docker registry proxy
* Create the Kind cluster
* Configure nodes for the registry proxy
* Install ingress-nginx, Kubernetes Dashboard, and Argo Workflows
* Create an `admin-user` account in the `kube-system` namespace and generate a login token that can be used to access the Dashboard and Argo Workflows UI
* Create an `workflow-user` account in the `argo` namespace that can be used to start argo workflows with something like `argo submit my-workflow.yaml -n argo --watch`

2. Copy the token logged by the script and log in to the **Kubernetes Dashboard**:

[https://localhost/dashboard](https://localhost/dashboard)

3. If port 80 or 443 is not available, you can adjust the values in `kind-cluster.yaml`.


### Docker Registry Proxy

The proxy listens inside the cluster at `docker-registry-proxy:3128`.
All cluster nodes are configured to pull images via this proxy automatically.


### Using Argo Workflows

With the Argo CLI, you can interact with the workflows running inside the cluster via the Ingress:

```bash

# List workflows
argo list -n argo

# Submit a workflow
argo submit workflows/hello-world.yaml -n argo --watch

# Get details of a workflow
argo get <workflow-name> -n argo
```

To login to the argo UI at [https://localhost/argo](https://localhost/argo), you have to enter `Bearer <TOKEN_VALUE_HERE>` in the auth field and click on "Login".


### Cleanup Cluster

Remove the cluster manually:

```bash
kind delete cluster --name kind-dev-cluster
```


## Help

If `kubectl config current-context` does not return `kind-kind-dev-cluster`, set it manually:

```bash
kubectl config use-context kind-kind-dev-cluster
```
