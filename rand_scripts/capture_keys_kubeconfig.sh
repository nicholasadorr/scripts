## capture client cert
export client=$(grep client-cert ~/.kube/config |cut -d" " -f 6)
echo $client

## capture client key
export key=$(grep client-key-data ~/.kube/config | cut -d " " -f 6)
echo $key

## capture certifcate auth info
export auth=$(grep certificate-authority-data ~/.kube/config | cut -d " " -f 6)
echo $auth

## create pems
echo $client | base64 -d - > ./client.pem
echo $key | base64 -d - > ./client-key.pem
echo $auth | base64 -d - > ./ca.pem

## sample use
curl --cert ./client.pem --key ./client-key.pem --cacert ./ca.pem https://<ip-of-cluster>:6443/api/v1/pods

curl --cert ./client.pem --key ./client-key.pem --cacert ./ca.pem https://<ip-of-cluster>:6443/api/v1/default/pods -XPOST -H'Content-Type: application/json' -d@testpod.json
