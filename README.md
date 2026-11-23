# K3s VM

A Terraform config and deployment scripts to create a Lima VM and deploy a single-node K3s cluster.

## Prerequisites

- Lima
- Terraform/OpenTofu
- uv

Create a local Python environment and install the Ansible requirements:

```bash
>uv venv
>uv run --with-requirements requirements.txt ansible-galaxy collection install -r ansible-galaxy-requirements.yaml
```

## Getting started

Create the VM

```bash
>cd terraform
>tofu init
>tofu apply -auto-approve
```

Check `limactl list` to see a VM called `k3s-lima` running.

Install the K3s cluster using ansible:

```bash
>uv run --with-requirements requirements.txt ansible-playbook k3s.orchestration.site -i inventory.yml
```

This will copy the Kube config to the host as a context called `k3s-lima` and set it to the current context.

Check `kubectl cluster-info` to show the details of the running cluster.
