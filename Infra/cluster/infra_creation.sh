#!/usr/bin/env -S bash -Eeuxo pipefail

# Set variables
rgname="b11duna"
aksname="AKSClusterDuna"
rgloc="francecentral"
redusrtraefik="devusertraefik"
redpasstraefik="password_redis_519"
apitoken="xKAj86qFn5Tj6WH5T2rENi4B"
certvers="v1.10.1"
Ingtraefik="traefik"

# Create resource group
echo "Creating resource group..."
az group create --location $rgloc --name $rgname
echo "Resource group created."

# Create AKS cluster
echo "Creating AKS cluster..."
az aks create -g $rgname -n $aksname --enable-managed-identity --node-count 2 --enable-addons monitoring --enable-msi-auth-for-monitoring --generate-ssh-keys
echo "AKS cluster created."

# Get AKS cluster credentials
echo "Getting AKS cluster credentials..."
az aks get-credentials --resource-group $rgname --name $aksname
echo "AKS cluster credentials retrieved."

# Install K9s
echo "Installing K9s..."
curl -sS https://webinstall.dev/k9s | bash
echo "The watchdog is here."

# Create Dev namespace
echo "Creating Prod namespace for traefik and voting-app..."
kubectl create namespace dev
echo "Namespaces created"

# Create Redis database secret
echo "Creating Redis database and Traefic secrets for namespace dev..."
kubectl create secret generic redis-secret-traefik --from-literal=username=$redusrtraefik --from-literal=password=$redpasstraefik -n dev
echo "Redis database and Traefik secrets created."

# Create traefik authentication secret
echo "Creating traefik authentication secret for namespace dev..."
echo -n 'devusertraefik:password_basicauth_648' | base64
echo "Please recevoer the result to put it in the basic authentication configuration of file values.yaml."

# Insert a pause in the script so that users can report password to values.yaml
read -n1 -r -p "Press Y to continue, or N to stop: " key

echo

if [ "$key" = 'Y' ] || [ "$key" = 'y' ]; then
    echo "Continuing..."
    # your code to execute if user presses Y goes here
elif [ "$key" = 'N' ] || [ "$key" = 'n' ]; then
    echo "Stopping..."
    exit 1
else
    # do nothing
    :
fi

# Create Redis database and deploying the Azure voting app
echo "Creating Redis database secret and deploying the Azure voting app..."
kubectl apply -f azure-vote.yaml -n dev
echo "Redis database secret created and Azure voting app deployed."

# Install traefik Ingress Controller
echo "Installing traefik Ingress Controller..."
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
# helm install $Ingtraefik traefik/traefik-n dev --debug --set controller.ingressClass="$Ingtraefik"
helm install $Ingtraefik traefik/traefik -n dev
kubectl apply --server-side --force-conflicts -k https://github.com/traefik/traefik-helm-chart/traefik/crds/ -n dev
echo "Traekif Ingress Controller installed."

# Break time for traefik to initialize
echo "Let's take 5 to let traefik settle in..."
sleep 30s
echo "Alright, let's steam ahead !"

# Extract External IP address
DevIngIP=$(kubectl get svc traefik -n dev -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "traefik (dev) Ingress: $DevIngIP"

# Insert a pause in the script so that users can report IP to DNS
read -n1 -r -p "Press Y to continue, or N to stop: " key

echo

if [ "$key" = 'Y' ] || [ "$key" = 'y' ]; then
    echo "Continuing..."
    # your code to execute if user presses Y goes here
elif [ "$key" = 'N' ] || [ "$key" = 'n' ]; then
    echo "Stopping..."
    exit 1
else
    # do nothing
    :
fi

# Install Traefik config/Apply Ingress layer
echo "Installing Traefik configuration"
kubectl apply -f traefik-middlewares.yaml -n dev
kubectl apply -f ingress_dev1.yaml -n dev
echo "Traefik (ingress) configuration file installed."

# Add Jetstack Helm repository
echo "Adding Jetstack Helm repository..."
helm repo add jetstack https://charts.jetstack.io
echo "Jetstack Helm repository added."

# Install cert-manager with custom DNS settings
echo "Installing cert-manager..."
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true --version v1.10.1 --set 'extraArgs={--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}'
echo "Cert-manager installed."

# Install cert-manager-webhook-gandi Helm chart
echo "Installing cert-manager-webhook-gandi Helm chart..."
helm install cert-manager-webhook-gandi --repo https://bwolf.github.io/cert-manager-webhook-gandi --version v0.2.0 --namespace cert-manager --set features.apiPriorityAndFairness=true --set logLevel=6 --generate-name
echo "cert-manager-webhook-gandi Helm chart installed."

# Apply Issuer layer
echo "Applying Let's Encrypt Issuer configuration files..."
kubectl apply -f issuer-dev.yaml -n dev
echo "Let's Encrypt Issuer configuration file applied."

# Create Gandi API token secret
echo "Creating Gandi API token secret..."
kubectl create secret generic gandi-credentials --from-literal=api-token=$apitoken
kubectl create secret generic gandi-credentials --from-literal=api-token=$apitoken -n dev
echo "Gandi API token secret created."

# Create role and rolebinding for accessing secrets
echo "Creating role and rolebinding for accessing secrets..."
hookID=$(kubectl get pods -n cert-manager | grep "cert-manager-webhook-gandi-" | cut -d"-" -f5)
kubectl create role access-secrets --verb=get,list,watch,update,create --resource=secrets -n dev
kubectl create rolebinding --role=access-secrets default-to-secrets --serviceaccount=cert-manager:cert-manager-webhook-gandi-$hookID -n dev
echo "Role and rolebinding created."

# Apply Certificate layer
echo "Applying Certificate configuration files..."
kubectl apply -f certif_dev.yaml -n dev
echo "Certificate configuration file applied."

# Apply Ingress layer
echo "Applying Ingress configuration files..."
kubectl apply -f ingress_dev2.yaml -n dev
echo "Ingress configuration file applied."

# Waiting for certificates
echo "Let's take 2' to let certificates to be presented..."
sleep 120s
echo "Alright, let's steam ahead !"

# Creating Kubeconfig for Azure Devops
echo "Creating the Kubeconfig for Azure DevOps..."
az aks get-credentials --resource-group $rgname --name $aksname -f kubeconfig.yaml
echo "Kubeconfig file generated. Do not forget to download the kubeconfig.yaml file to get the data and remove it if it is created in your git."

# Check certificate
echo "Let's check our certificates"
kubectl get certificate --all-namespaces