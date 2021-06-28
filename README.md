# terraform_mos

A collection of terraform deployment scripts to deploy `OS`

- alpine
- centos
- debian
- fedora
- opensuse-leap
- opensuse-tumbleweed
- ubuntu

on `PLATFORM`

- Libvirt: Tested

## Requirements

* Terraform >= v0.13.0./provider/<PLATFORM>/<OS>/
* Terraform-libvirt-provider >= v0.6.3. Need to follow instructions in https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/docs/migration-13.md to setup terraform local registry

## Configuration

```
cp ~/src/github.com/cclhsu/terraform_mos/providers/<PLATFORM>/<OS>/terraform.tfvars.example ~/src/github.com/cclhsu/terraform_mos/providers/<PLATFORM>/<OS>/terraform.tfvars
```

Change configurations accordingly.

## Deploy

```
cd ~/src/github.com/cclhsu/terraform_mos/providers/<PLATFORM>/<OS>/
terraform init
terraform apply -auto-approve
```

## Undeploy

```
cd ~/src/github.com/cclhsu/terraform_mos/providers/<PLATFORM>/<OS>/
terraform destroy -auto-approve -parallelism=1
```
