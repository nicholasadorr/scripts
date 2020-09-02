## capture token of master and test limits
k config view
kg secrets --all-namespaces
kg secrets
kdes secret default-token-qqrl2
export token=$(kubectl describe secret default-token-qqrl2 | grep ^token | cut -f7 -d ' ')
echo $token
curl https://<ip>:6443/apis --header "Authorization: Bearer $token" -k
curl https://<ip>:6443/apis --header "Authorization: Bearer $token" -k | less
curl https://<ip>:6443/api/v1 --header "Authorization: Bearer $token" -k | less
curl https://<ip>:6443/api/v1/namespaces --header "Authorization: Bearer $token" -k | less

## test using proxy to get access to cluster api
k proxy -h
kubectl proxy --api-prefix=/ & # note the process id
curl http://127.0.0.1:8001/api/v1/namespaces
curl http://127.0.0.1:8001/api/v1/namespaces | less
kill <process id>

