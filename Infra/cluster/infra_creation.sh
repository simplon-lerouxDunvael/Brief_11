#!/usr/bin/env -S bash -Eeuxo pipefail

# Set variables
rgname="b11duna"
aksname="AKSClusterDuna"
rgloc="francecentral"
redusrtreafik="devusertreafik"
redpasstreafik="password_redis_519"
BasicAuthuser="devusertreafik"
BasicAuthpass="password_basicauth_648"
apitoken="xKAj86qFn5Tj6WH5T2rENi4B"
certvers="v1.10.1"
IngTreafik="treafik-dev"


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
echo "Creating Prod namespace for Treafik and voting-app..."
kubectl create namespace dev
echo "Namespaces created"

# Create Redis database secret
echo "Creating Redis database secret for namespace dev..."
kubectl create secret generic redis-secret-treafik --from-literal=username=$redusrtreafik --from-literal=password=$redpasstreafik -n dev
echo "Redis database secret created."

# Create Treafik authentication secret
echo "Creating Treafik authentication secret for namespace dev..."
kubectl create secret generic basicAuth-treafik-secret --from-literal=username=$BasicAuthuser --from-literal=password=$BasicAuthpass -n dev
echo "Treafik authentication secret created."

# Create Redis database and Treafik secrets
echo "Creating Redis database and Treafik secrets..."
kubectl apply -f azure-vote.yaml -n dev
echo "Redis database and Treafik secrets created."

# Install Treafik Ingress Controller
echo "Installing Treafik Ingress Controller..."
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm install $IngTreafik traefik/traefik -f values.yaml -n dev --debug --set controller.ingressClass="$IngTreafik"
echo "Treakif Ingress Controller installed."

# Break time for Treafik to initialize
echo "Let's take 5 to let Treafik settle in..."
sleep 30s
echo "Alright, let's steam ahead !"

# # Extract External IP address
# DevIngIP=$(kubectl get svc treafik-dev-treafik-ingress-controller -n dev -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
# echo "Treafik (dev) Ingress: $DevIngIP"

# # Insert a pause in the script so that users can report IP to DNS
# read -n1 -r -p "Press Y to continue, or N to stop: " key

# echo

# if [ "$key" = 'Y' ] || [ "$key" = 'y' ]; then
#     echo "Continuing..."
#     # your code to execute if user presses Y goes here
# elif [ "$key" = 'N' ] || [ "$key" = 'n' ]; then
#     echo "Stopping..."
#     exit 1
# else
#     # do nothing
#     :
# fi

# # Configure Treafik as reverse proxy for the voting app
# echo "Let's configure Treafik as reverse proxy"
# kubectl apply -f azure-vote2.yaml -n dev
# echo "Treafik is now configured as reverse proxy for the Voting app."

# # Add Jetstack Helm repository
# echo "Adding Jetstack Helm repository..."
# helm repo add jetstack https://charts.jetstack.io
# echo "Jetstack Helm repository added."

# # Install cert-manager with custom DNS settings
# echo "Installing cert-manager..."
# helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true --version v1.10.1 --set 'extraArgs={--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}'
# echo "Cert-manager installed."

# # Install cert-manager-webhook-gandi Helm chart
# echo "Installing cert-manager-webhook-gandi Helm chart..."
# helm install cert-manager-webhook-gandi --repo https://bwolf.github.io/cert-manager-webhook-gandi --version v0.2.0 --namespace cert-manager --set features.apiPriorityAndFairness=true --set logLevel=6 --generate-name
# echo "cert-manager-webhook-gandi Helm chart installed."

# # Apply applicative layers
# echo "Applying applicative configuration files..."
# kubectl apply -f azure-vote.yaml -n qua
# kubectl apply -f azure-vote.yaml -n prod
# echo "Applicative configuration files applied"

# # Apply Ingress layer
# echo "Applying Ingress configuration files..."
# kubectl apply -f ingress_qua1.yaml -n qua
# kubectl apply -f ingress_prod1.yaml -n prod
# echo "Ingress configuration files applied."

# # Apply Issuer layer
# echo "Applying Let's Encrypt Issuer configuration files..."
# kubectl apply -f issuer-qua.yaml -n qua
# kubectl apply -f issuer-prod.yaml -n prod
# echo "Let's Encrypt Issuer configuration files applied."

# # Create Gandi API token secret
# echo "Creating Gandi API token secret..."
# kubectl create secret generic gandi-credentials --from-literal=api-token=$apitoken
# kubectl create secret generic gandi-credentials --from-literal=api-token=$apitoken -n qua
# kubectl create secret generic gandi-credentials --from-literal=api-token=$apitoken -n prod
# echo "Gandi API token secret created."

# # Create role and rolebinding for accessing secrets
# echo "Creating role and rolebinding for accessing secrets..."
# hookID=$(kubectl get pods -n cert-manager | grep "cert-manager-webhook-gandi-" | cut -d"-" -f5)
# kubectl create role access-secrets --verb=get,list,watch,update,create --resource=secrets -n qua
# kubectl create role access-secrets --verb=get,list,watch,update,create --resource=secrets -n prod
# kubectl create rolebinding --role=access-secrets default-to-secrets --serviceaccount=cert-manager:cert-manager-webhook-gandi-$hookID -n qua
# kubectl create rolebinding --role=access-secrets default-to-secrets --serviceaccount=cert-manager:cert-manager-webhook-gandi-$hookID -n prod
# echo "Role and rolebinding created."

# # Apply Certificate layer
# echo "Applying Certificate configuration files..."
# kubectl apply -f certif_qua.yaml -n qua
# kubectl apply -f certif_prod.yaml -n prod
# echo "Certificate configuration files applied."

# # Apply Ingress layer
# echo "Applying Ingress configuration files..."
# kubectl apply -f ingress_qua2.yaml -n qua
# kubectl apply -f ingress_prod2.yaml -n prod
# echo "Ingress configuration files applied."

# # Waiting for certificates
# echo "Let's take 2' to let certificates to be presented..."
# sleep 120s
# echo "Alright, let's steam ahead !"

# # Creating Kubeconfig for Azure Devops
# echo "Creating the Kubeconfig for Azure DevOps..."
# az aks get-credentials --resource-group $rgname --name $aksname -f kubeconfig.yaml
# echo "Kubeconfig file generated."

# # Check certificate
# echo "Let's check our certificates"
# kubectl get certificate --all-namespaces

# # Check ingresses
# echo "Let's check our ingresses"
# kubectl get ing --all-namespaces
# echo ""
# echo "Be sure to get the data from kubeconfig.yaml and remove it if it is created in your git."