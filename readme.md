# k0s on AWS with Cilium CNI

This installation includes k0s (Default CNI kuberouter deactivated), Cilium as CNI, AWS Cloud Controller Manager & AWS EBS CSI Driver

## Prep

Get and apply your AWS creds in the terminal, so we can use Terraform to create resources. 

## Installation

terraform apply -auto-approve

terraform output -raw k0s_cluster | k0sctl apply --no-wait --debug --config -

terraform output -raw k0s_cluster | k0sctl kubeconfig --config -

et voilà, a k0s cluster with 1 controller, 3 worker, integration into AWS and Cilium as CNI.


### TODO
- Make iam_instance_profile configurable
- Make AMI configurable