# Local kind dev cluster

This project provides a local kubernetes dev cluster.
It should never be used in a production environment.
The only intention is to provide a quick and easy local dev playground.

It is based on [kind](https://kind.sigs.k8s.io/) (kubernetes in docker) and the web-based dashboard user interface is pre-installed by adding these apps to the cluster:

* [ingress-nginx](https://github.com/kubernetes/ingress-nginx)
* [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
* [Argo Workflows](https://argoproj.github.io/workflows/)

## Requirements

* [Docker](https://docs.docker.com/engine/install/)
* [kind](https://kind.sigs.k8s.io/)
* [helm](https://helm.sh/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Usage

Just execute the `kind.sh` script of this project.

Be patient and wait until the script has finished.

Copy the token that has been logged by the script and login [here](https://localhost/dashboard).

In case you are not able to run on port 80 or 443, you can change the values in the `kind-cluster.yaml` config file.

### Cleanup cluster

The cluster can be removed manually via

```shell
kind delete clusters kind-dev-cluster
```

## Help

In case `kubectl config current-context` does not return `kind-kind-dev-cluster`, you can set it with `kubectl config use-context kind-kind-dev-cluster`.
