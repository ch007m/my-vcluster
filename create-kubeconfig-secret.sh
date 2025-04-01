
CLUSTER_NAME=${1:-worker-1}
CLUSTER_NS=${CLUSTER_NAME}
SECRET_NAME=vc-${CLUSTER_NAME}

#kubectl get secret/$SECRET_NAME -n $CLUSTER_NS -ojson | jq -r '.'
#kubectl get secret/$SECRET_NAME -n $CLUSTER_NS -ojson | jq -r '.data."certificate-authority" | @base64d'
#kubectl get secret/$SECRET_NAME -n $CLUSTER_NS -ojson | jq -r '.data."client-certificate" | @base64d'
#kubectl get secret/$SECRET_NAME -n $CLUSTER_NS -ojson | jq -r '.data."client-key" | @base64d'

# Encode values in base64
#CA_DATA=$(echo -n "$CERTIFICATE_AUTHORITY" | base64 -w 0)
#CERT_DATA=$(echo -n "$CLIENT_CERTIFICATE" | base64 -w 0)
#KEY_DATA=$(echo -n "$CLIENT_KEY" | base64 -w 0)

CA_DATA=$(kubectl get secret/$SECRET_NAME -n $CLUSTER_NS -ojson | jq -r '.data."certificate-authority"')
CERT_DATA=$(kubectl get secret/$SECRET_NAME -n $CLUSTER_NS -ojson | jq -r '.data."client-certificate"')
KEY_DATA=$(kubectl get secret/$SECRET_NAME -n $CLUSTER_NS -ojson | jq -r '.data."client-key"')

kubectl delete -n argocd secret/$SECRET_NAME

echo "apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: $SECRET_NAME
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
stringData:
  name: $SECRET_NAME
  server: https://$SECRET_NAME.cnoe.localtest.me:8443
  config: |
    {
      \"tlsClientConfig\": {
        \"insecure\": false,
        \"caData\": $CA_DATA,
        \"certData\": $CERT_DATA,
        \"keyData\": $KEY_DATA
      }
    }" | kubectl apply -f -