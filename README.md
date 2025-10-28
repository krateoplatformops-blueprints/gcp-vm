# GCP Virtual Machine provisioning Blueprint

This Blueprint provisions a Google Cloud Platform (GCP) Virtual Machine (VM).

In particular, it creates the following resources:
- Compute Instance
- Compute Disk
- Compute Network
- Compute Subnetwork

which represent the minimal set of resources required to create a VM in GCP.

## Requirements

- Install and setup Config Connector in your cluster. Follow the official instructions [here](https://cloud.google.com/config-connector/docs/how-to/install-other-kubernetes).

## Usage

### Install the Helm Chart

Download Helm Chart values:
```sh
helm repo add marketplace https://marketplace.krateo.io
helm repo update marketplace
helm inspect values marketplace/gcp-vm --version 1.0.0 > ~/gcp-vm-values.yaml
```

Modify the *gcp-vm-values.yaml* file as the following example:
```yaml
namespace: gcp
vmName: test-vm-dummy1
vmSize: e2-small
vmRegion: europe-central2
```

Install the Blueprint:
```sh
helm install <release-name> gcp-vm \
  --repo https://marketplace.krateo.io \
  --namespace <release-namespace> \
  --create-namespace \
  -f ~/gcp-vm-values.yaml
  --version 1.0.0 \
  --wait
```

### Install using Krateo Composable Operation

Install the CompositionDefinition for the *Blueprint*:
```sh
cat <<EOF | kubectl apply -f -
apiVersion: core.krateo.io/v1alpha1
kind: CompositionDefinition
metadata:
  name: gcp-vm
  namespace: krateo-system
spec:
  chart:
    repo: gcp-vm
    url: https://marketplace.krateo.io
    version: 1.0.0
EOF
```

Install the Blueprint using, as metadata.name, the *Composition* name (the Helm Chart name of the composition):
```sh
cat <<EOF | kubectl apply -f -
apiVersion: composition.krateo.io/v1-0-0
kind: GcpVm
metadata:
  name: <release-name>
  namespace: <release-namespace>
spec:
  namespace: gcp
  vmName: test-vm-dummy1
  vmSize: e2-small
  vmRegion: europe-central2
EOF
```

### Install using Krateo Composable Portal

```sh
cat <<EOF | kubectl apply -f -
apiVersion: core.krateo.io/v1alpha1
kind: CompositionDefinition
metadata:
  name: portal-blueprint-page
  namespace: krateo-system
spec:
  chart:
    repo: portal-blueprint-page
    url: https://marketplace.krateo.io
    version: 1.0.5
EOF
```

Install the Blueprint using, as metadata.name, the *Blueprint* name (the Helm Chart name of the blueprint):

```sh
cat <<EOF | kubectl apply -f -
apiVersion: composition.krateo.io/v1-0-5
kind: PortalBlueprintPage
metadata:
  name: gcp-vm
  namespace: demo-system
spec:
  blueprint:
    url: https://marketplace.krateo.io
    version: 1.0.0 # this is the Blueprint version
    hasPage: false
  form:
    alphabeticalOrder: false
  panel:
    title: GCP VM
    icon:
      name: fa-cubes
EOF
```
