# Instructions to create vclusters with idpbuilder on a kind kubernetes cluster

The purpose of this project is to simulate an environment similar to what it is deployed within company's facilities where the users have access to different machines/servers deployed on `dev`, `test` or `prod` environments using kubernetes and vclusters.

For that purpose we will create top of an IDPlatform different vclusters - https://www.vcluster.com/docs. The tool which is used under the hood to install the resources from files or helm chart on the kubernetes cluster is: Argo CD.

As each vcluster is exposed behind a Kubernetes API; it is then needed to create a Secret containing the kubeconfig that Argocd will use to access them and to register it as [Cluster](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#clusters). 

To populate the secret, we are using the help of [Kyverno](https://kyverno.io/) and a `ClusterPolicy`. See the policy's file [here](generate-secrets/manifests/kyverno-policy.yml). For more information about how to create a policy, see the [doc](https://kyverno.io/docs/writing-policies/match-exclude/) page.

**Remark**: The matching rule used part of the policy is looking to one of the worker's names: worker-1, worker-2 ... worker-5. Such a hard coded list of values should be defined as a parameter if we convert the `generate-secrets` package into a helm chart to get rid of that !

To create 2 vclusters: `worker-1` and `worker-2` using idpbuilder, then execute the following command
```shell
idpbuilder create \
  --color \
  --dev-password \
  --name idplatform \
  --port 8443 \
  -p vcluster \
  -p kyverno --recreate  
```
**Note**: You can add more vclusters or change the properties of the section `spec/generators/list/elements[]` by editing locally the ApplicationSet file: [vcluster.yaml](vcluster/vcluster.yaml) which is used to create the clusters.

When the vclusters are created, then we can execute the following package able to generate the Argocd secret containing the `tlsConfig` allowing Argo CD to access the different Kubernetes API Servers !

```shell
idpbuilder create \
  --color \
  --dev-password \
  --name idplatform \
  --port 8443 \
  -p vcluster \
  -p kyverno \
  -p generate-secrets
```

When the process completed, you will see for each `vcluster` a new namespace containing the: kube api, coredns and etcd pods
```shell
worker-1                 coredns-bbb5b66cc-sgbkc-x-kube-system-x-worker-1        ●       1/1        Running                       0 10.244.0.24        idplatform-control-plane        3m23s
worker-1                 worker-1-0                                              ●       1/1        Running                       0 10.244.0.17        idplatform-control-plane        4m1s
worker-2                 coredns-bbb5b66cc-cpd9g-x-kube-system-x-worker-2        ●       1/1        Running                       0 10.244.0.23        idplatform-control-plane        3m23s
worker-2                 worker-2-0
```

Next, you can deploy a guestbook application against a vcluster using an Argo CD Application resource.
The helm resources will be deployed under the `demo` namespace of the vcluster.
```shell
echo "apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  destination:
    server: worker-1
    namespace: demo
  project: default
  source:
    repoURL: https://github.com/ch007m/my-vcluster
    targetRevision: HEAD
    path: helm-guestbook
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - RespectIgnoreDifferences=true
    - ApplyOutOfSyncOnly=true" | kubectl apply -f -
```

Check if the Application is `sync/healthy` and look to the pod created under the vcluster
```shell
❯ ./scripts/get-vcluster-kubeconfig.sh worker-1
❯ kubectl --kubeconfig=worker-1-kube.cfg get ns
NAME              STATUS   AGE
default           Active   4m35s
demo              Active   55s
❯ kubectl --kubeconfig=worker-1-kube.cfg get pods -A
NAMESPACE     NAME                                        READY   STATUS    RESTARTS   AGE
demo          guestbook-helm-guestbook-7fd6c45ccf-z8zqf   1/1     Running   0          45s
kube-system   coredns-bbb5b66cc-k5km2                     1/1     Running   0          4m19s
```
TODO: Investigate why 
- we only got as pod the coredns one and not the guestbook's pod
- the matching rule of kyverno don't accept wildcard to find secrets having names: `vc-*` except `vc-config-*` - https://github:com/kyverno/kyverno/discussions/12614

## Useful articles

The following blog post is very interesting as it show how such a secret could be populated dynamically using kyverno: https://piotrminkowski.com/2022/12/09/manage-multiple-kubernetes-clusters-with-argocd/ (see section: Automatically Adding Argo CD Clusters with Kyverno)

## TODO

Review the clusterPolicy based on this example: https://github.com/kyverno/policies/blob/main/argo/argo-cluster-generation-from-rancher-capi/argo-cluster-generation-from-rancher-capi.yaml#L35-L101

## Troubleshoot

```shell
argocd login argocd.cnoe.localtest.me:8443 --grpc-web --insecure --username admin --password developer
argocd cluster list
argocd cluster get worker-1 -o wide
argocd cluster get worker-1
```