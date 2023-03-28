#!/bin/bash

# Set the namespace for the Helm charts
namespace="testing"
kubeconfig_file=$1

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo -e "\e[91mkubectl is not installed. Please install kubectl and try again.\e[0m"
  exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
  echo -e "\e[91mHelm is not installed. Please install Helm and try again.\e[0m"
  exit 1
fi

# Check if figlet is installed, and install it if it's not
if ! command -v figlet &> /dev/null; then
  echo -e "\e[93mfiglet is not installed, installing it now...\e[0m"
  sudo apt-get update
  sudo apt-get install figlet -y
fi

# Print Sunbird Learn ASCII art banner using figlet
figlet -f slant "Sunbird Learn Installation"

# Create the learn namespace if it doesn't exist
if ! kubectl get ns $namespace >/dev/null 2>&1; then
  kubectl create ns $namespace
  echo -e "\e[92mCreated namespace $namespace\e[0m"
fi

# Check if the kubeconfig file exists
if [ ! -f "$kubeconfig_file" ]; then
    echo "Error: Kubeconfig file not found."
    exit 1
fi

# Check connectivity with the Kubernetes cluster
kubectl --kubeconfig="$kubeconfig_file" cluster-info >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Unable to connect to the Kubernetes cluster with the provided kubeconfig file."
    exit 1
fi

echo "Success: Connected to the Kubernetes cluster with the provided kubeconfig file."

# Create the learn namespace if it doesn't exist
if ! kubectl get namespace $namespace >/dev/null 2>&1; then
  kubectl create namespace $namespace
  echo -e "\e[92mCreated namespace $namespace\e[0m"
fi

# Loop through the CSV file and install the Helm charts
while IFS=',' read -r chart_name chart_version chart_repo; do
  if [ -z "$chart_repo" ]; then
    echo "Error: Repository URL not found for $chart_name in charts.csv"
    exit 1
  fi

  # Update the Helm repository
  if ! helm repo list | grep -q $chart_name; then
    helm repo add $chart_name $chart_repo
    helm repo update
  fi

  # Check if the chart is already installed
  if helm list -n $namespace | grep -q $chart_name; then
    echo "$chart_name is already installed."
  else
    # Install the chart with global variables
    helm install $chart_name $chart_name/$chart_name --version $chart_version -n $namespace -f global-values.yaml
  fi
done < charts.csv
