# k0s with Cilium and AWS Integration

This repository provides an automated Terraform-based installation of **k0s** with **Cilium as the CNI**, along with AWS integrations such as:
- **AWS Cloud Controller Manager**
- **AWS EBS CSI Driver**
- **AWS EBS StorageClass**

By using this Terraform setup, you can quickly deploy a **k0s** cluster on AWS with cloud provider integration, networking via **Cilium**, and persistent storage via **EBS**.

---

## Prerequisites
Before proceeding with the installation, ensure you have the following:

- An AWS account with required IAM permissions.
- Terraform (`>=0.14.3`) installed.
- `kubectl` installed and configured.
- `k0sctl` installed for cluster configuration management.

---

## 🚀 Automated Installation with Terraform
The entire deployment, including AWS EC2 instances, security groups, key pairs, and k0s configuration, is managed via Terraform.

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Apply Terraform Configuration
```bash
terraform apply -auto-approve
```

### 3. Deploy k0s Cluster with k0sctl
```bash
terraform output -raw k0s_cluster | k0sctl apply --no-wait --debug --config -
```

### 4️. Retrieve kubeconfig for Cluster Access
```bash
terraform output -raw k0s_cluster | k0sctl kubeconfig --config -
```
You can save the kubeconfig in a file for the use with `kubectl` or just just run `k0sctl` e.g. `terraform output -raw k0s_cluster | k0sctl kc get no`

---

## Terraform Details
This Terraform configuration does the following:
- Creates an **AWS Key Pair** for SSH access.
- Generates a **TLS private key** for authentication.
- Provisions **EC2 instances** for controllers and workers.
- Configures **AWS Security Groups** to allow necessary traffic.
- Deploys **k0s** with external cloud provider integration.
- Installs **Cilium, AWS Cloud Controller Manager, and EBS CSI Driver** via Helm.

### **Example Terraform Configuration**
The Terraform module includes:
- **Key Pair Management**: Creates an SSH key pair and saves the private key locally.
- **Security Group Setup**: Allows SSH access and required network traffic.
- **Dynamic k0s Cluster Configuration**: Generates the k0s configuration dynamically with Helm charts for required services.
- **Storage Setup**: Configures AWS EBS StorageClass for persistent storage.

---

## Verification
After installation, verify the components:
```sh
kubectl get nodes --kubeconfig config
kubectl get pods -n kube-system --kubeconfig config
kubectl get storageclass --kubeconfig config
```
Ensure that Cilium is correctly managing networking:
```sh
cilium status
```

---

## Contributing
Contributions are welcome! To contribute:
1. Fork this repository.
2. Create a new branch (`feature/your-feature-name`).
3. Commit your changes (`git commit -m 'Add new feature'`).
4. Push to your branch (`git push origin feature/your-feature-name`).
5. Open a pull request.

For major changes, please open an issue first to discuss your ideas.

---

## License
This project is open-source and available under the **MIT License**.

---

### TODO
- Make iam_instance_profile configurable
- Make AMI configurable