# Instructions to create vclusters with idpbuilder

The purpose of this project is to simulate an environment similar to what it is deployed within company's facilities where the users have access to `dev`, `test` or `'prod` environments using vclusters.

For that purpose we will create top of an IDPlatform different vclusters - https://www.vcluster.com/docs
and will generate the secret's file containing the kubeconfig / tls configuration to access the Kubernetes Api of the vcluster using a [Kyverno policy](https://kyverno.io/).

So let's create some vclusters: `worker-1` and `worker-2`
```shell
idpbuilder create \
  --color \
  --dev-password \
  --name idplatform \
  --port 8443 \
  -p kyverno \
  -p vcluster \
  -p generate-secrets
```

**Note**: You can add more vclusters or change the properties by editing locally the ApplicationSet file: [vcluster.yaml](vcluster/vcluster.yaml)

## Useful articles

The following blog post is very interesting as it show how such a secret could be populated dynamically using kyverno: https://piotrminkowski.com/2022/12/09/manage-multiple-kubernetes-clusters-with-argocd/ (see section: Automatically Adding Argo CD Clusters with Kyverno)
