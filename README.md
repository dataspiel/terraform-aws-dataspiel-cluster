# Terraform module for dataspiel on AWS

*Warning: the code in this repository is currently alpha release quality and
very much work-in-progress. Use at your own risk!*

A [terraform](https://www.terraform.io/) module to provision a Kubernetes
cluster (using EKS) and supporting infrastructure on AWS. This cluster can
then be used to deploy open-source services commonly used for data engineering
and science (such as Apache Airflow or Apache Spark).

The actual services are deployed using gitops and are not part of this
repository, here only the foundational infrastructure pieces are included.

Infrastructure that is currently deployed amongst other:

* EKS cluster
* Route53 hosted zone
* EFS file system as a shared filesystem
* KMS key for encrypting secrets


## Usage

See `examples` for how to define a basic Terraform workspace. You can copy
the folder and adjust to your own needs. Afterwards run `terraform init` and
`terraform plan` / `terraform apply`. Especially the deployment of the EKS cluster
will take a while (~10mins).

## Development

Install the pre-commit hooks:

```
pre-commit install
```

Check all the files with pre-commit checks:

```
pre-commit run --all-files
```
