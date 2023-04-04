terraform {
  required_version = ">= 0.14.3"
}

provider "aws" {
  region = "eu-central-1"
}

resource "tls_private_key" "k0sctl" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "cluster-key" {
  key_name   = format("%s_key", var.cluster_name)
  public_key = tls_private_key.k0sctl.public_key_openssh
}

// Save the private key to filesystem
resource "local_file" "aws_private_pem" {
  file_permission = "600"
  filename        = format("%s/%s", path.module, "aws_private.pem")
  content         = tls_private_key.k0sctl.private_key_pem
}

resource "aws_security_group" "cluster_allow_ssh" {
  name        = format("%s-allow-ssh", var.cluster_name)
  description = "Allow ssh inbound traffic"
  // vpc_id      = aws_vpc.cluster-vpc.id

  // Allow all incoming and outgoing ports.
  // TODO: need to create a more restrictive policy
  ingress {
    description = "SSH from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = format("%s-allow-ssh", var.cluster_name)
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}


locals {
  k0s_tmpl = {
    apiVersion = "k0sctl.k0sproject.io/v1beta1"
    kind       = "cluster"
    spec = {
      hosts = [
        for host in concat(aws_instance.cluster-controller, aws_instance.cluster-workers) : {
          ssh = {
            address = host.public_ip
            user    = "ubuntu"
            keyPath = "./aws_private.pem"
          }
          installFlags = [
            "--enable-cloud-provider",
            "--kubelet-extra-args=\"--cloud-provider=external\""
          ]
          role = host.tags["Role"]
        }
      ]
      k0s = {
        version = "1.26.2+k0s.0"
        dynamicConfig = false
        config = {
          apiVersion = "k0s.k0sproject.io/v1beta1"
          kind = "Cluster"
          metadata = {
            name = "k0s-cilium-cluster"
          }
          spec = {
            api = {
              address = aws_instance.cluster-controller[0].public_ip
              externalAddress = aws_instance.cluster-controller[0].public_ip
              k0sApiPort = 9443
              port = 6443
              sans = [
                aws_instance.cluster-controller[0].public_ip
              ]
              tunneledNetworkingMode = false
            }
            controllerManager = {}
            installConfig = {
              users = {
                etcdUser = "etcd"
                kineUser = "kube-apiserver"
                konnectivityUser = "konnectivity-server"
                kubeAPIserverUser = "kube-apiserver"
                kubeSchedulerUser = "kube-scheduler"
              }
            }
            network = {
              kubeProxy = {
                disabled = false
                mode = "iptables"
              }
              podCIDR = "10.244.0.0/16"
              provider = "custom"
              serviceCIDR = "10.96.0.0/12"
            }
            storage = {
              type = "etcd"
            }
            telemetry = {
              enabled = true
            }
            extensions = {
              helm = {
                repositories = [
                  {
                    name = "cilium"
                    url = "https://helm.cilium.io/"
                  },
                  {
                    name = "aws-cloud-controller-manager"
                    url = "https://kubernetes.github.io/cloud-provider-aws"
                  }
                ]
                charts = [
                  {
                    name = "cilium"
                    chartname = "cilium/cilium"
                    namespace = "kube-system"
                    version = "1.13.1"
                  },
                  {
                    name = "aws-cloud-controller-manager"
                    chartname = "aws-cloud-controller-manager/aws-cloud-controller-manager"
                    namespace = "kube-system"
                    version = "0.0.7"
                    values = <<-EOT
                      args:
                        - --v=2
                        - --cloud-provider=aws
                        - --allocate-node-cidrs=false
                        - --cluster-cidr=172.20.0.0/16
                        - --cluster-name=k0s-cilium-cluster
                      nodeSelector:
                        node-role.kubernetes.io/control-plane: "true"
                    EOT
                  }
                ]
              }
            }
          }
        }
      }
    }
  }
}

output "k0s_cluster" {
  value = replace(yamlencode(local.k0s_tmpl), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
}
