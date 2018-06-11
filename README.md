# brastemp

:package: Proof-of-concept of a cluster infrastructure to deploy containers in the cloud.

## Technology

Here's a brief overview of the technology stack:

- [**AWS**](https://www.aws.amazon.com) as the major cloud provider.
- [**Terraform**](https://www.terraform.io) to provision the infrastructure from the ground up.
- [**Packer**](https://www.packer.io) used to build the and package the base AMI and [**Ansible**](https://www.ansible.com) to configure, install and provision the base AMIs.
- [**Consul**](https://www.consul.io) used as a service discovery tool.
- [**Nomad**](https://www.nomadproject.io) to run and deploy services.
- [**Docker**](https://www.docker.com) to run the applications inside containers.
- [**Traefik**](https://www.traefik.io) used as a reverse proxy to expose the services to the web.

## Usage

1. Build the packer images:

```sh
$ cd amis/
$ packer build brastemp.json
```

2. Terraform the base infrastructure:

```sh
$ cd infra/
$ terraform apply
```

3. Build and run the featured applications with nomad:

```sh
$ cd apps/
$ terraform apply
```
