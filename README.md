# Local kind dev cluster

This project provides a local kubernetes dev cluster.
It should never be used in a production environment.
The only intention is to provide a quick and easy local dev playground.

It is based on [kind](https://kind.sigs.k8s.io/) (kubernetes in docker) and the web-based dashboard user interface is pre-installed by adding these apps to the cluster:

* [ingress-nginx](https://github.com/kubernetes/ingress-nginx)
* [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)

## Requirements

* [Docker](https://docs.docker.com/engine/install/)
* [kind](https://kind.sigs.k8s.io/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Usage

Just execute the `kind.sh` script of this project.

Be patient and wait until you see `Starting to serve on 127.0.0.1:8001`.

Copy the token that has been logged by the script and login [here](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/).
