<div style='text-align: justify;'>

<div id='top'/>

# Integrating Traefik Proxy to secure access to a webapp

## Summary

###### [00 - Daily Scrum](#Scrum)

###### [01 -  Doc reading](#Doc)

###### [02 - Creation of a resource group and deployment of Voting-App](#RG)

###### [03 - Issues and resolution](#issues)

###### [04 - TLS](#tls)

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

After deploying my script, traefik was installed. 

![2023-07-03_svc_deployed](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/76538b64-32ee-420c-9c6f-b3fdaf70b6e4)

I created a DNS record to link it to traefik IP address. 

![2023-07-03_dns_record-traefik](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/a6f6dc7e-553e-4b5c-81b1-f9310148072f)

After checking the services and pods, traefik is running however I can't connect to the Voting-App with both the IP address and the DNS.

![2023-07-03_no_connection_to_dns](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/932a40bf-9f56-404c-bc0a-196195815ea3)

After checking my deployments `kubectl get deployments -n dev`, I noticed that the Azure Voting-app was not deployed. I tried to manually deploy the file and had an error message saying that my traefik secret did not respect the syntax. It has to be in lowercase only and cannot have any uppercase (it had one). So I updated my secret's name and my azure-vote.yaml file.

![2023-07-04 10h20_error_message_unvalid_secret_name](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/cfe54fb2-5bcf-4939-94b8-4c9a0163cb39)

Then I deleted my cluster and RG and redeployed everything.

However the result is the same. I ckecked the domain resolution with `nslookup smoothie-traefik.simplon-duna.space`.

![2023-07-04 11h23_nslookup_working](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/7af4fa9a-f238-4b4d-bd18-0bc5152df93b)

The output of the nslookup command shows that the domain "smoothie-traefik.simplon-duna.space" is successfully resolved and points to the internal IP address 10.224.0.6. This means that DNS resolution is working fine from where I ran the nslookup command.

Then I checked traefik services `k describe svc traefik-dev-traefik -n dev` :

![2023-07-04 11h34_describe_traefik_svc](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/ac6fc464-56ab-411d-96cb-5d85167f82e7)

It seems that he traefik service is currently configured for internal access only and is not accessible from the Internet. 

To make the service accessible from the outside, I have to modify its configuration to put it in external (public) LoadBalancer mode and obtain an external public IP address.

In order to do this, I need to check the configuration used when installing traefik via Helm and ensure that the appropriate parameter for the type of service (LoadBalancer) is set to "External". I also consult the Helm and traefik documentation to understand how to configure the type of LoadBalancer I want.

I also checked the ingress with `kubectl get ingress -n dev` :

![2023-07-04 11h49_no_ingress_found](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/7aba018d-5b15-4b7b-8e1f-7acf9eb6f66a)

It seems that traefik is not seen as an ingress.
So I went to [traefik doc](https://doc.traefik.io/traefik/routing/overview/).

After checking all this, I went to my values.yaml traefik configuration file and updated the annotation `service.beta.kubernetes.io/azure-load-balancer-internal` from "true" to "false". This way, the load balancer will be configured externally and will be accessible from outside the Kubernetes cluster.

![2023-07-04 11h56_configure_LBinternal_false](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/8c66de22-f304-4a20-8c34-bb635298bfeb)

In order to update traefik's config, I need to update it with helm with its config file. As I used this command to install it with Helm `helm install traefik-dev traefik/traefik -f values.yaml -n dev --debug --set controller.ingressClass="traefik-dev"`, I used this command to upgrade it : 

```bash
helm upgrade traefik-dev traefik/traefik -n dev -f values.yaml
```

![2023-07-04 12h05_traefikconfig_upgraded_with_helm](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/2b249978-c4bb-4f7d-b3a9-3fed3f8b2eee)

Then I checked traefik'services and it had a new external IP address. I updated my DNS record with it.

![2023-07-04 12h08_traefik_externalIP](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/e5017ff2-abd0-4e2b-a028-730c067cbc64)


Then I tried to connect. I now have a 404 page error but it seems the issue is no more traefik's configuration. It is now available externally.

![2023-07-04 12h11_404error](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/df261e01-8dae-40f7-b025-51ba43d3c2a4)

After checking with Joffrey, I found out that my values.yaml configuration file does not change anything to the 404 error. 

*I went to this [doc](https://artifacthub.io/packages/helm/traefik/traefik) that refers the default parameters for traefik's configuration.*

Therefore, I choose to follow Joffrey's advices and to provide another route with another port (used by traefik) to my voting app to see if this could solve the issue.

I updated Traefik config file values.yaml. I added routing rules :

* one "whoami-http" to be able to connect in HTTP ad=nd configure an entrypoint for the azure voting-app (and smoothie-traefik.simplon-duna.space)
* one "whoami-https" to be able to connect in HTTP and HTTPS when the TLS will be configured and to redirect all HTTP trafic to HTTPS

Then I updated the voting app service on my azure-vote.yaml file :

* I added websecure to the annotations (entrypoints)
* I added the HTTPS ports and the targetport that will be used by Traefik to direct trafic (wheither it is in HTTP or HTTPS). *As I already specified the targetport in the deployment of my azure voting app I do not need to add it.*

I still have the 404 error after all these steps.

[&#8679;](#top)

<div id='issues'/>  

### **Issues and resolution**

I decided to deploy the first file ingress_dev1.yaml in order to solve this 404 error.

But when I tried to deploy it I had several error message. They indicated that Kubernetes couldn't find the custom resource definition (CRD) for the IngressRoute kind in the traefik.containo.us/v1 version I had specified in my file. 

![2023-07-05 09h47_crds_installed](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/b3f36a4a-f960-4f63-8531-a4377cd01d46)

So I updated my file with `traefik.v1alpha1` and deployed it. As I had the same error message, I decided to remove `IngressRoute` and just put `Ingress`.

As nothing I did was working, I decided to do things differently.

I updated my ingress_dev1.yaml file with the same API version and kind used for Nginx but with specific annotations for traefik (found in this [Traefik documentation](https://doc.traefik.io/traefik/middlewares/http/basicauth/)).

![2023-07-05 12h26_ingress_updated](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/e993ba1a-0ec2-4726-b4d1-113a044c541f)

I deleted my basicauth-traefik secret I had created before so I could create an encoded user:password pair that I could put in my basicauthentication middleware. To do so I used the following command :

```bash
echo -n 'devusertraefik:password_basicauth_648' | base64
```

Then I created a traefik-middlewares.yaml file to deploy the basic authentication for Traefik and the IP whitelisting. I put the encoded password in my secret in data>users.

![2023-07-05 12h31_password-encoded](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/428836d0-a11b-4599-95a6-8acbfc4f5c05)

I then updated my traefik config with : 

```bash
helm upgrade traefik-dev traefik/traefik -n dev
```

I also updated the voting app image used in my azure-vote.yaml with the one in my docker repository.

Then I applied my files in this order :

* traefik-middlewares.yaml
* ingress_dev1.yaml
* azure-vote.yaml

The issue was still there.

After Joffrey's and Luna's help the issue was solved :

I uninstalled and reinstalled traefik with helm : 

```bash
helm install traefik traefik/traefik -n dev
kubectl apply --server-side --force-conflicts -k https://github.com/traefik/traefik-helm-chart/traefik/crds/ -n dev
```

```bash
curl smoothie-traefik.simplon-duna.space
```

I changed my ingress class from traefik-dev to traefik only for the reinstallation.

I also installed the software Lens to be able to check my Kubernetes cluster and have more visual details about its services, pods, logs, network connections and configurations.

After modifying all this it still did not work for me while it worked for Joffrey and Luna. Same issue after cleaning my cache, on private navigation and on another browser.
We came to the conclusion that my ISP was blocking the access to `smoothie-traefik.simplon-duna.space`. After updating my wifi card I could finally connect to my application through Traefic.

![2023-07-05 15h41_finally_connected_in_http](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/f6d522af-5829-4225-99b4-5b19486d0e99)

Then I updated my values.yaml file in order to redeploy it and use its config for Traefik instead of the kubernetes traefik-middlewares.yaml file I previsouly had to use.

Then I redeployed my ingress_dev1.yaml file and updated Traefik with the now updated values.yaml config file :

```bash
helm upgrade traefik traefik/traefik -n dev -f values.yaml
```

I had several other issues. So I decided to redeploy completly my cluster and use middlewares instead of the values.yaml file that did not work properly.

To configure my basicauth middleware I had to create an encoded password. However the command I previsouly used was not correct for this middleware. So, in orderto gain some time, Joffrey created an encoded password for me :

```bash
htpasswd -nb test test | base64
```

I put the output in my middleware basicauth. *I will have to install apache2-utils on [WSL](https://learn.microsoft.com/fr-fr/windows/wsl/install-manual) for next time to avoid issues such as this one.*
I also ran the following command so that my ip address would not be modified (as a local ip address) and so I would not be denied access to the application: 

```bash
kubectl patch svc traefik -p '{"spec":{"externalTrafficPolicy":"Local"}}' -n dev
```

After configuring the middleware and linking it to my ingress_dev1.yaml file (with the right namespaces), I could finally connect to my application and being prompted for username and password. I commented my whitelist middleware as it seems to not be working yet.

Message prompted to the user during connection to the application :

![2023-07-06 13h49_prompting_screen_working](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/e8663a9d-76b5-4472-9642-ac03da7b033d)

When the prompted screen is exited this error message is displayed to the user :

![2023-07-06 13h49_unauthorized](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/b80897ac-741c-4b6c-9ddd-2768ec763c1c)

Once this was completed, I added an ip range to my whitelist middleware and applied the traefik-middlewares.yaml file once again. Then I tried to connectand had no issue. I asked Luna to connect (she is at home) and she had a forbidden error message. My ip whitelisting is correctly configured.

[&#8679;](#top)

--------

<div id='tls'/>  

### **TLS**

After all these steps, I downloaded Loom to be able to records my objectives.

Then I started to integrate TLS certificate so I could connect in HTTPS to my application.

I modified my certif_dev.yaml, issuer-dev.yaml and ingress_dev2.yaml files in order to be able to properly configure my TLS.

I also updated my bash script and ran it to :

* add Jetstack Helm repository
* install cert-manager with custom DNS settings
* install cert-manager-webhook-gandi Helm chart
* apply the Issuer layer
* create Gandi API token secret
* create role and rolebinding for accessing secrets
* apply the certificate layer
* apply Ingress (traefik) layer

Then I tried to connect in HTTPS to my application and it worked fine. 

![2023-07-06 15h43_https_installed](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/245d945d-af5f-4fce-a679-aaccec0fcf27)

As I added a rule to forbid HTTP trafic (in my ingress_dev2.yaml file) I had an error message when I tried to connect in HTTP to my application.

![2023-07-06 15h59_rule_for_trafic](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/74292a9c-2e54-4648-b886-cacf81807ac8)

![2023-07-06 15h54_http_not_allowed](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/a5e21678-6ce1-478e-aa2e-8d142e2b91ec)

As it worked fine, I changed the acme server on my issuer-dev.yaml file so it would not be the test server (<https://acme-staging-v02.api.letsencrypt.org/directory>) anymore but the original server (<https://acme-v02.api.letsencrypt.org/directory>). This way, my application would truly be in HTTPS.

Then I deleted my tls secrets and certificates, the issuer-dev.yaml and certif_dev.yaml files and redeployed my issuer-dev.yaml file and connected in HTTPS to `smoothie-traefik.simplon-duna.space`.

![2023-07-06 16h18_true_https_connection_working](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/5ec42e3b-6e46-4076-ac80-fbb174cd5890)

[&#8679;](#top)

--------

<div id=''/>  

### **Google authentication**

In order to complete the fifth objective and activate OAuth with Google
ID, I had to follow several steps :

Step 1: I had to setup my Google Developer Account 

* I went to the [Google Developers Console](https://console.developers.google.com) (I created a new project as I did not have one)

![2023-07-06 16h29_google_console](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/00598793-4880-4afa-8d52-a50ba9a44f2d)

![2023-07-06 16h38_project_creation](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/bda47011-8999-4d37-8fdb-1f419f5d5f91)


* In the project, I accessed to the "Identifiers" tab in the left menu

![2023-07-06 16h43_creation_of_project](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/16775d91-6dea-48a4-9468-7d5658d51ea2)

* Then I clicked on "Create credentials" and chose "OAuth client identifier"

![2023-07-06 16h50_oauth_creation](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/d38d07ab-c92a-4c11-8389-6aa8a92ab7e9)

* I selected the appropriate application type ("Web application")
* In the "Authorized JavaScript origins" and "Authorized redirect URIs" section, I added the appropriate URLs for my Traefik application
* Then I copied the "Client ID" (21511219386-1gdp9495l6lp3mjdmdvn7mpdgq0vpqe9.apps.googleusercontent.com)and the "Client Secret" (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) (necessary for the configuration of Traefik)

![2023-07-06 16h53_oauth_created_successfuly](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/1605f595-97f4-4711-a3ae-add93adcef41)

Step 2 : I created a traefik-middlewares2.yaml file with the OAuth of Google

* I created a traefik-middlewares2.yaml file and I added the middleware for OAuth and added my client ID and secret ID (previously created and saved)
* I deleted the traefik-middlewares.yaml file with `kubectl delete -f traefik-middlewares.yaml -n dev`
* I deployed the traefik-middlewares2.yaml file

![2023-07-06 16h59_middleware_file_updated_with_oauth](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/198ad650-87bb-4139-8ab5-6abc1b4a0553)

Step 3 : I created an ingress_dev3.yaml file that I could push for the OAuth authentication

* I created an ingress_dev3.yaml file with the proper annotations
* I deleted the ingress_dev2.yaml file with `kubectl delete -f ingress_dev2.yaml -n dev`
* I deployed the ingress_dev3.yaml file

![2023-07-07 10h06_traefik_updated](https://github.com/simplon-lerouxDunvael/Brief_11/assets/108001918/dfeab32a-0379-47c6-81dd-4786a6484482)


[&#8679;](#top)

--------

<div id='videos'/>  

### **Link to videos**

* [first video](https://www.loom.com/share/cbe0523fd286472995a88be5d810d896?sid=fb407319-ecd5-41aa-ba74-db01e822e0c3)
* [second video](https://www.loom.com/share/4869667fff04452c926936295f899d8c?sid=3d18f8bb-71b4-4446-822d-8f779ba101e3)
* [third video](https://www.loom.com/share/4b430498574647ff9cce2ee8e5684aec?sid=98255a3a-1203-4479-94a2-01c4515ac583)

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
