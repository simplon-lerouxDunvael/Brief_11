<div style='text-align: justify;'>

<div id='top'/>

# Integrating Traefik Proxy to secure access to a webapp

## Summary

###### [00 - Daily Scrum](#Scrum)

###### [01 -  Doc reading](#Doc)

###### [02 - Creation of a resource group](#RG)

###### [03 - ](#)

###### [04 - ](#)

###### [05 - ](#)

###### [06 - ](#)

###### [07 - ](#)

###### [08 - ](#)

###### [09 - ](#)

&nbsp;&nbsp;&nbsp;[a) ](#)  
&nbsp;&nbsp;&nbsp;[b) ](#)  
&nbsp;&nbsp;&nbsp;[c) ](#)  

###### [10 - ](#)

###### [11 - ](#)

###### [12 - Usefull Commands](#UsefullCommands)

<div id='Scrum'/>  

### **Scrum quotidien**

Scrum Master = Me, myself and I
Daily personnal reactions with reports and designations of first tasks for the day.

Frequent meeting with other coworkers to study solutions to encountered problems together.

[scrums](https://github.com/simplon-lerouxDunvael/Brief_7/blob/main/Plans_et_demarches/Scrum.md)

[&#8679;](#top)

<div id='Docs'/>  

#### **doc reading**

Researches and reading of documentations to determine the needed prerequisites, functionnalities and softwares to complete the different tasks of Brief 10.

[&#8679;](#top)  

<div id='RG'/>  

### **Creation of a resource group and deployment of Voting-App**

I created a resource group and deployed the AKS cluster via the file script .sh (created and updated beforehand). I also directly installed K9s in order to check logs. To connect to it, I opened a terminal and typed `k9s` and clicked `Enter`. 

![k9s](https://github.com/simplon-lerouxDunvael/Brief_10/assets/108001918/1494fbdc-d11c-488a-900e-4a047de71034)

To get out of the graphic interface, I just clicked on `Ctrl + C`.

![k9s-2](https://github.com/simplon-lerouxDunvael/Brief_10/assets/108001918/59a34173-8d39-41f9-addc-08bfe89d693b)

After deploying my script, Treafik was installed. 

![2023-07-03_svc_deployed](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/76538b64-32ee-420c-9c6f-b3fdaf70b6e4)

I created a DNS record to link it to Treafik IP address. 

![2023-07-03_dns_record-treafik](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/a6f6dc7e-553e-4b5c-81b1-f9310148072f)

After checking the services and pods, Treafik is running however I can't connect to the Voting-App with both the IP address and the DNS.

![2023-07-03_no_connection_to_dns](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/932a40bf-9f56-404c-bc0a-196195815ea3)

After checking my deployments `kubectl get deployments -n dev`, I noticed that the Azure Voting-app was not deployed. I tried to manually deploy the file and had an error message saying that my Treafik secret did not respect the syntax. It has to be in lowercase only and cannot have any uppercase (it had one). So I updated my secret's name and my azure-vote.yaml file.

![2023-07-04 10h20_error_message_unvalid_secret_name](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/cfe54fb2-5bcf-4939-94b8-4c9a0163cb39)

Then I deleted my cluster and RG and redeployed everything.

However the result is the same. I ckecked the domain resolution with `nslookup smoothie-treafik.simplon-duna.space`.

![2023-07-04 11h23_nslookup_working](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/7af4fa9a-f238-4b4d-bd18-0bc5152df93b)

The output of the nslookup command shows that the domain "smoothie-treafik.simplon-duna.space" is successfully resolved and points to the internal IP address 10.224.0.6. This means that DNS resolution is working fine from where I ran the nslookup command.

Then I checked treafik services `k describe svc treafik-dev-traefik -n dev` :

![2023-07-04 11h34_describe_treafik_svc](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/ac6fc464-56ab-411d-96cb-5d85167f82e7)

It seems that he Treafik service is currently configured for internal access only and is not accessible from the Internet. 

To make the service accessible from the outside, I have to modify its configuration to put it in external (public) LoadBalancer mode and obtain an external public IP address.

In order to do this, I need to check the configuration used when installing Treafik via Helm and ensure that the appropriate parameter for the type of service (LoadBalancer) is set to "External". I also consult the Helm and Treafik documentation to understand how to configure the type of LoadBalancer I want.

I also checked the ingress with `kubectl get ingress -n dev` :

![2023-07-04 11h49_no_ingress_found](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/7aba018d-5b15-4b7b-8e1f-7acf9eb6f66a)

It seems that Treafik is not seen as an ingress.
So I went to [Treafik doc](https://doc.traefik.io/traefik/routing/overview/).

After checking all this, I went to my values.yaml Treafik configuration file and updated the annotation `service.beta.kubernetes.io/azure-load-balancer-internal` from "true" to "false". This way, the load balancer will be configured externally and will be accessible from outside the Kubernetes cluster.

![2023-07-04 11h56_configure_LBinternal_false](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/8c66de22-f304-4a20-8c34-bb635298bfeb)

[&#8679;](#top)

<div id=''/>  

### ****

[&#8679;](#top)

--------

<div id=''/>  

### ****

[&#8679;](#top)

--------

<div id=''/>  

### ****

[&#8679;](#top)

--------

<div id=''/>  

### ****

[&#8679;](#top)

--------

<div id=''/>  

### ****

[&#8679;](#top)

--------

<div id=''/>  

### ****

[&#8679;](#top)

--------

<div id=''/>  

### ****

[&#8679;](#top)

--------

<div id=''/>  

### ****

[&#8679;](#top)

--------

<div id=''/>  

### ****

[&#8679;](#top)

--------

<div id=''/>  

### ****

[&#8679;](#top)

--------

<div id='UsefullCommands'/>  

### **USEFULL COMMANDS**

### **To clone and pull a GitHub repository**

```bash
git clone [GitHubRepositoryURL]
```

```bash
git pull
```

[&#8679;](#top)

### **To create an alias for a command on azure CLi**

alias [WhatWeWant]="[WhatIsChanged]"  

*Example :*  

```bash
alias k="kubectl"
```

[&#8679;](#top)

### **To deploy resources with yaml file**

kubectl apply -f [name-of-the-yaml-file]

*Example :*  

```bash
kubectl apply -f azure-vote.yaml
```

[&#8679;](#top)

### **To check resources**

```bash
kubectl get nodes
kubectl get pods
kubectl get services
kubectl get deployments
kubectl get events
kubectl get secrets
kubectl get logs
helm list --all-namespaces
k get ingressclass --all-namespaces
```

*To keep verifying the resources add --watch at the end of the command :*

*Example :*

```bash
kubectl get services --watch
```

*To check the resources according to their namespace, add --namespace after the command and the namespace's name :*

*Example :*

```bash
kubectl get services --namespace [namespace's-name]
```

[&#8679;](#top)

### **To describe resources**

```bash
kubectl describe nodes
kubectl describe pods
kubectl describe services # or svc
kubectl describe deployment # or deploy
kubectl describe events
kubectl describe secrets
kubectl describe logs
```

*To specify which resource needs to be described just put the resource ID at the end of the command.*

*Example :*

```bash
kubectl describe svc redis-service
```

*To access to all the logs from all containers :*

```bash
kubectl logs podname --all-containers
```

*To access to the logs from a specific container :*

```bash
kubectl logs podname -c [container's-name]
```

*To list all events from a specific pod :*

```bash
kubectl get events --field-selector [involvedObject].name=[podsname]
```

[&#8679;](#top)

### **To delete resources**

```bash
kubectl delete deploy --all
kubectl delete svc --all
kubectl delete pvc --all
kubectl delete pv --all
kubectl delete ingress --all
kubectl delete secrets --all
kubectl delete certificates --all
az group delete --name [resourceGroupName] --yes --no-wait

kubectl delete deployments --all -n [namespaceName]
kubectl delete pods --all -n [namespaceName]
kubectl delete replicaset --all -n [namespaceName]
kubectl delete statefulset --all -n [namespaceName]
kubectl delete daemonset --all -n [namespaceName]
kubectl delete svc --all -n [namespaceName]
kubectl delete namespace [namespaceName]
kubectl delete clusterrole prometheus-grafana-clusterrole
kubectl delete clusterrole prometheus-kube-state-metrics
kubectl delete clusterrole system:prometheus
kubectl delete clusterrolebinding --all -n [namespaceName]
k delete ingressclass [insert ingressclass] --all-namespaces
```

[&#8679;](#top)

### **To check TLS certificate in request order**

```bash
kubectl get certificate
kubectl get certificaterequest
kubectl get order
kubectl get challenge
```

[&#8679;](#top)

### **To describe TLS certificate in request order**

```bash
kubectl describe certificate
kubectl describe certificaterequest
kubectl describe order
kubectl describe challenge
```

[&#8679;](#top)

### **Get the IP address to point the DNS to nginx in the two namespaces**

```bash
kubectl get svc --all-namespaces
```

[&#8679;](#top)

</div>
