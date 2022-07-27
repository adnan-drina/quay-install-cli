# Quay install using CLI
Deploy Red Hat Quay v3.7 container registry on OpenShift 4.10 using the Quay Operator.

This repo is based on official Quay documentation [DEPLOY RED HAT QUAY ON OPENSHIFT WITH THE QUAY OPERATOR](https://access.redhat.com/documentation/en-us/red_hat_quay/3.7/html/deploy_red_hat_quay_on_openshift_with_the_quay_operator/index)

## Object Storage setup
By default, the Red Hat Quay Operator uses the ObjectBucketClaim Kubernetes API to provision object storage. Consuming this API decouples the Operator from any vendor-specific implementation. Red Hat OpenShift Data Foundation provides this API via its NooBaa component, which will be used in this example.
Ensure that the RHOCS operator exists in the channel catalog. Login to your OCP 4.10 cluster as admin and execute the following command:
```shell script
oc get packagemanifests -n openshift-marketplace | grep odf
```

Query the available channels for ODF operator
```shell script
oc get packagemanifest -o jsonpath='{range .status.channels[*]}{.name}{"\n"}{end}{"\n"}' -n openshift-marketplace odf-operator
```

Discover whether the operator can be installed cluster-wide or in a single namespace
```shell script
oc get packagemanifest -o jsonpath='{range .status.channels[*]}{.name}{" => cluster-wide: "}{.currentCSVDesc.installModes[?(@.type=="AllNamespaces")].supported}{"\n"}{end}{"\n"}' -n openshift-marketplace odf-operator
```
To install an operator in a specific project (in case of cluster-wide false), you need to create first an OperatorGroup in the target namespace. An OperatorGroup is an OLM resource that selects target namespaces in which to generate required RBAC access for all Operators in the same namespace as the OperatorGroup.

### Create a Project for ODF
[odf-namespace.yaml](ODF/odf-namespace.yaml)
```yaml
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    openshift.io/description: "Red Hat OpenShift Data Foundation"
    openshift.io/display-name: "ODF"
  name: openshift-storage
  labels:
    openshift.io/cluster-monitoring: "true"
```
```shell script
oc apply -f ODF/odf-namespace.yaml
```

### Create an OperatorGroup
[odf-og.yaml](ODF/odf-og.yaml)
```yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-storage
spec:
  targetNamespaces:
    - openshift-storage
```
```shell script
oc apply -f ODF/odf-og.yaml
```

### Create an ODF Subscription
[odf-sub.yaml](ODF/odf-sub.yaml)
```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: odf-operator
  namespace: openshift-storage
spec:
  channel: stable-4.10
  installPlanApproval: Automatic
  name: odf-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```
```shell script
oc apply -f ODF/odf-sub.yaml
```

### Label nodes
In order for ODF to configure storage using this overlay it expects nodes with the following label to be present on the nodes ODF will install the cluster:
```
cluster.ocs.openshift.io/openshift-storage=""
```

You will need to manually add this label to nodes if they are not already present:
```
oc label nodes <node-name> cluster.ocs.openshift.io/openshift-storage="" --overwrite=true
```

To label all worker nodes in your cluster run following script
```
./ODF/odf-label-nodes.sh
```

### Create a StorageSystem
Create a StorageSystem to represent your OpenShift Data Foundation system and all its required storage and computing resources.
[odf-storagesystem.yaml](ODF/odf-storagesystem.yaml)
```yaml
apiVersion: odf.openshift.io/v1alpha1
kind: StorageSystem
metadata:
  name: ocs-storagecluster-storagesystem
spec:
  kind: storagecluster.ocs.openshift.io/v1
  name: ocs-storagecluster
  namespace: openshift-storage
```

```shell script
oc apply -f ODF/odf-storagesystem.yaml
```

### Create a Storage Cluster

```yaml
apiVersion: ocs.openshift.io/v1
kind: StorageCluster
metadata:
  name: ocs-storagecluster
  namespace: openshift-storage
spec:
  arbiter: {}
  encryption:
    kms: {}
  externalStorage: {}
  managedResources:
    cephBlockPools: {}
    cephConfig: {}
    cephDashboard: {}
    cephFilesystems: {}
    cephObjectStoreUsers: {}
    cephObjectStores: {}
  mirroring: {}
  nodeTopologies: {}
  storageDeviceSets:
    - config: {}
      count: 1
      dataPVCTemplate:
        metadata: {}
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 2Ti
          storageClassName: gp2
          volumeMode: Block
        status: {}
      name: ocs-deviceset-gp2
      placement: {}
      portable: true
      preparePlacement: {}
      replica: 3
      resources: {}
  version: 4.10.0
```

```shell script
oc apply -f ODF/odf-storagecluster.yaml
```

### ODF Initialization

```yaml
apiVersion: ocs.openshift.io/v1
kind: OCSInitialization
metadata:
  name: ocsinit
  namespace: openshift-storage
spec:
  enableCephTools: true
```

```shell script
oc apply -f ODF/odf-initialization.yaml
```

---

## Quay Setup

Ensure that the Quay operator exists in the channel catalog.
```shell script
oc get packagemanifests -n openshift-marketplace | grep quay
```

Query the available channels for Quay operator
```shell script
oc get packagemanifest -o jsonpath='{range .status.channels[*]}{.name}{"\n"}{end}{"\n"}' -n openshift-marketplace quay-operator
```

Discover whether the operator can be installed cluster-wide or in a single namespace
```shell script
oc get packagemanifest -o jsonpath='{range .status.channels[*]}{.name}{" => cluster-wide: "}{.currentCSVDesc.installModes[?(@.type=="AllNamespaces")].supported}{"\n"}{end}{"\n"}' -n openshift-marketplace quay-operator
```

Check the CSV information for additional details
```shell script
oc describe packagemanifests/quay-operator -n openshift-marketplace | grep -A36 Channels
```

### Create a Project for Quay
[quay-namespace.yaml](quay-namespace.yaml)
```yaml
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    openshift.io/description: "Red Hat Quay Enterprise Container Image Repository"
    openshift.io/display-name: "Quay"
  name: quay
```
```shell script
oc apply -f quay-namespace.yaml
```

### Create a Quay Subscription
[quay-sub.yaml](quay-sub.yaml)
```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: quay-operator
  namespace: openshift-operators
spec:
  channel: stable-3.7
  installPlanApproval: Automatic
  name: quay-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```
```shell script
oc apply -f quay-sub.yaml
```

### Create Config Bundle secret

[quay-config-bundle-secret.yaml](quay-config-bundle-secret.yaml)
```yaml
kind: Secret
apiVersion: v1
metadata:
  name: config-bundle-secret
  namespace: quay
data:
  clair-config.yaml: >-
    bWF0Y2hlcnM6CiAgY29uZmlnOgogICAgY3JkYToKICAgICAga2V5OiAxMGZjZDliMDE2MDNkNTdlNjg4N2E0MzQ5MjZiMzIwMA==
  config.yaml: >-
    RkVBVFVSRV9CVUlMRF9TVVBQT1JUOiB0cnVlCkZFQVRVUkVfR0VORVJBTF9PQ0lfU1VQUE9SVDogdHJ1ZQpGRUFUVVJFX0hFTE1fT0NJX1NVUFBPUlQ6IHRydWU=
type: Opaque
```
```shell script
oc apply -f quay-config-bundle-secret.yaml
```

### Deploy QuayRegistry

[quay-cr.yaml](quay-cr.yaml)
```yaml
apiVersion: quay.redhat.com/v1
kind: QuayRegistry
metadata:
  name: container-registry
  namespace: quay
spec:
  components:
    - managed: true
      kind: clair
    - managed: true
      kind: postgres
    - managed: true
      kind: objectstorage
    - managed: true
      kind: redis
    - managed: true
      kind: horizontalpodautoscaler
    - managed: true
      kind: route
    - managed: true
      kind: mirror
    - managed: true
      kind: monitoring
    - managed: true
      kind: tls
    - managed: true
      kind: quay
    - managed: true
      kind: clairpostgres
  configBundleSecret: quay-config-bundle-secret
```
```shell script
oc apply -f quay-cr.yaml
```

Retrieve all the created objects belonging to the operator
```shell script
oc get $(oc get $CSV -o json |jq -r '[.spec.customresourcedefinitions.owned[]|.name]|join(",")')
```

### Access Quay GUI
```shell script
oc get routes
```
You should see 3 routes:
- container-registry-quay — is for connecting to the registry

connect to the route named **container-registry-quay** using your browser

you'll need to create an account

### Test
login to Quay
```shell script
podman login -u="quay" -p="password" quayecosystem-quay-quay.<YOUR-DOMAIN> --tls-verify=false
```
pull ubi image from registry.access.redhat.com
```shell script
podman pull registry.access.redhat.com/ubi8/ubi:latest
```
push ubi to quay/myrepo 
```shell script
podman push registry.access.redhat.com/ubi8/ubi quayecosystem-quay-quay.<YOUR-DOMAIN>/quay/myrepo:ubi --tls-verify=false
```
verify in quay that image is received and no vulnerabilities are found

pull minecraft-server from docker.io
```shell script
podman pull docker.io/itzg/minecraft-server:latest
```
push minecraft-server to quay/myrepo
```shell script
podman push docker.io/itzg/minecraft-server quayecosystem-quay-quay.<YOUR-DOMAIN>/quay/myrepo:minecraft --tls-verify=false
```
verify in quay that image is received and Clair has found vulnerabilities


## Install Quay Security Operator

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: container-security-operator
  namespace: openshift-operators
spec:
  channel: quay-v3.4
  installPlanApproval: Automatic
  name: container-security-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```
```shell script
oc apply -f quay-security.yaml
```