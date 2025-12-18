#!/bin/bash

# Variables
TERRAFORM_VERSION="1.14.2"
HELIX_VERSION="25.07.1"
KIND_VERSION="v0.30.0"
KUBECTL_VERSION="v1.34.2"
HELM_VERSION="v3.19.2"

case $(uname -m) in
  x86_64)  ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
esac


echo "Installing System Utilities..."
sudo apt-get update
sudo apt-get install -y \
    curl \
    git \
    unzip \
    tar \
    less \
    groff \
    bash-completion


echo "Installing Docker & Docker Compose..."
curl -fsSL https://get.docker.com | sh
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
echo "Docker successfully installed!"


echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip
mkdir -p ~/.aws
echo "AWS CLI successfully installed!"

echo "Installing Terraform..."
curl "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" -o terraform.zip
unzip -q terraform.zip
sudo mv terraform /usr/local/bin/
rm terraform.zip LICENSE.txt
echo "Terraform successfully installed!"

echo "Installing Kind..."
curl -L "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}" -o ./kind
chmod +x kind
sudo mv kind /usr/local/bin/
echo "Kind successfully installed!"

echo "Installing Kubectl..."
curl -L "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" -o kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
mkdir -p ~/.kube
echo "Kubectl successfully installed!"

echo "Installing Helm..."
curl -L "https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz" -o helm.tar.gz
tar -zxvf helm.tar.gz --strip-components=1 linux-${ARCH}/helm
sudo mv helm /usr/local/bin/
rm helm.tar.gz
echo "Helm successfully installed!"

echo "Installing Helix..."
curl -L "https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-$(uname -m)-linux.tar.xz" -o helix.tar.xz
tar -xf helix.tar.xz
sudo rm -rf /opt/helix
sudo mv helix-${HELIX_VERSION}-*-linux /opt/helix
sudo ln -sf /opt/helix/hx /usr/local/bin/hx
rm -rf helix.tar.xz 
echo "Helix successfully installed!"

echo "source /etc/profile.d/bash_completion.sh" >> ~/.bashrc \
    && echo "source <(kubectl completion bash)" >> ~/.bashrc \
    && echo "source <(helm completion bash)" >> ~/.bashrc \
    && echo "source <(kind completion bash)" >> ~/.bashrc \
    && echo "source <(docker completion bash)" >> ~/.bashrc \
    && echo "complete -C /usr/local/bin/terraform terraform" >> ~/.bashrc \
    && echo "complete -C /usr/local/bin/aws_completer aws" >> ~/.bashrc \
    && echo "alias k=kubectl" >> ~/.bashrc \
    && echo "complete -o default -F __start_kubectl k" >> ~/.bashrc

source ~/.bashrc

mkdir -p ~/Coding/Dockerfile
