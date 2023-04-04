# k0s on AWS with Cilium CNI

## Prep

Get and apply your AWS creds in the terminal, so we can use Terraform to create resources. 

## Installation

terraform apply -auto-approve

terraform output -raw k0s_cluster | k0sctl apply --no-wait --debug --config -

terraform output -raw k0s_cluster | k0sctl kubeconfig --config -

et voilà, a k0s cluster with 1 controller, 3 worker and Cilium as CNI.


### TODO
- Make iam_instance_profile configurable
- Make AMI configurable