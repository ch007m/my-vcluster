
CLUSTER_NAME=${1:-worker-1}
CLUSTER_NS=${CLUSTER_NAME}
SECRET_NAME=vc-${CLUSTER_NAME}

kubectl get secret/$SECRET_NAME -n $CLUSTER_NS -ojson | jq -r '.data.config | @base64d' > "${CLUSTER_NAME}-kube.cfg"
#chmod yq e '(.. | select(has("server")).server) |= sub(":443$"; ":8443")' -i cluster-0-kube.cfg