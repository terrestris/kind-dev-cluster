kubectl get -n kubernetes-dashboard secret/admin-user-secret -o=jsonpath='{.data.token}' | base64 -d
