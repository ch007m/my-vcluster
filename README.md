# Instructions to create vclusters with idpbuilder

The purpose of this project is to simulate an environment similar to what it is deployed within company's facilities where the users have access to different machines/servers deployed on `dev`, `test` or `prod` environments using kubernetes and vclusters.

For that purpose we will create top of an IDPlatform different vclusters - https://www.vcluster.com/docs. The tool which is used under the hood to install the resources from files or helm chart on the kubernetes cluster is: Argo CD.

As each vcluster is exposed behind a Kubernetes API; it is then needed to create a Secret containing the kubeconfig that Argocd will use to access them. To populate the secret, we are using the help of [Kyverno](https://kyverno.io/) and a `ClusterPolicy`. See the policy's file [here](generate-secrets/manifests/kyverno-policy.yml).

To create 2 vclusters: `worker-1` and `worker-2` using idpbuilder, then execute the following command
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

When the process completed, you will see for each `vcluster` a new namespace containing the: kube api, coredns and etcd pods
```shell
worker-1             coredns-bbb5b66cc-8k6mx-x-kube-system-x-worker-1           1/1     Running     0          123m
worker-1             worker-1-5b6b5fcd96-hjffx                                  1/1     Running     0          125m
worker-1             worker-1-etcd-0                                            1/1     Running     0          125m
worker-2             coredns-bbb5b66cc-44q4c-x-kube-system-x-worker-2           1/1     Running     0          123m
worker-2             worker-2-6f88c5697f-fdxxb                                  1/1     Running     0          125m
worker-2             worker-2-etcd-0                                            1/1     Running     0          125m
```

**Note**: You can add more vclusters or change the properties of the section `spec/generators/list/elements[]` by editing locally the ApplicationSet file: [vcluster.yaml](vcluster/vcluster.yaml)

Next, you can deploy a guestbook application against a vcluster using an Application resource
```shell
echo "apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  destination:
    server: https://kubernetes.default.svc
    namespace: worker-1
  project: default
  source:
    path: helm-guestbook
    repoURL: https://github.com/argoproj/argocd-example-apps
    targetRevision: HEAD
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    retry:
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 10m
    syncOptions:
    - CreateNamespace=true
    - RespectIgnoreDifferences=true
    - ApplyOutOfSyncOnly=true" | kubectl apply -f -
```

Check if the Application is `sync/healthy` and look to the pod created under the vcluster
```shell
./get-vcluster-kubeconfig.sh worker-1
kubectl --kubeconfig=worker-1-kube.cfg get pods
NAMESPACE     NAME                      READY   STATUS    RESTARTS   AGE
kube-system   coredns-bbb5b66cc-8k6mx   1/1     Running   0          24m
```
TODO: Investigate why we only got as pod the coredns one and not the guestbook's pod

## Useful articles

The following blog post is very interesting as it show how such a secret could be populated dynamically using kyverno: https://piotrminkowski.com/2022/12/09/manage-multiple-kubernetes-clusters-with-argocd/ (see section: Automatically Adding Argo CD Clusters with Kyverno)
