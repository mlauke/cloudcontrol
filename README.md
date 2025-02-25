# CloudControl ☁️ 🧰

The cloud engineer's toolbox.

## Introduction

*CloudControl* is a [Docker](https://docker.com) based configuration environment containing all the tools
required and configured to manage modern cloud infrastructures.

The toolbox comes in different "flavours" depending on what cloud you are working in.
Currently supported cloud flavours are:

* ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/dodevops/cloudcontrol-aws?sort&#x3D;semver) [AWS](https://hub.docker.com/r/dodevops/cloudcontrol-aws) (based on [amazon/aws-cli](https://hub.docker.com/r/amazon/aws-cli))
* ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/dodevops/cloudcontrol-azure?sort&#x3D;semver) [Azure](https://hub.docker.com/r/dodevops/cloudcontrol-azure) (based on [mcr.microsoft.com/azure-cli](https://hub.docker.com/_/microsoft-azure-cli))

Following features and tools are supported:

* 🐟 Fish Shell
* 📷 AzCopy
* ⚙️  Direnv
* ⛵️ Helm
* 🛠  JQ
* ⌨️ kc Quick Kubernetes Context switch
* 🐚 Kubectlnodeshell
* 🐳 Kubernetes
* 📦 Packages
* 📦 Packer
* 👟 Run
* 📜 Stern
* 🌏 Terraform
* 🐗 Terragrunt
* 🕰 Timezone configuration
* 🌊 Velero
* 𝑉  Vim
* 🛠  YQ

## Table of contents

* [Usage](#usage)
* [Using Kubernetes](#using-kubernetes)
* [FAQ](#faq)
* [Flavours](#flavours)
    * [aws](#aws)
    * [azure](#azure)
* [Features](#features)
    * [fish](#fish)
    * [azcopy](#azcopy)
    * [direnv](#direnv)
    * [helm](#helm)
    * [jq](#jq)
    * [kc](#kc)
    * [kubectlnodeshell](#kubectlnodeshell)
    * [kubernetes](#kubernetes)
    * [packages](#packages)
    * [packer](#packer)
    * [run](#run)
    * [stern](#stern)
    * [terraform](#terraform)
    * [terragrunt](#terragrunt)
    * [timezone](#timezone)
    * [velero](#velero)
    * [vim](#vim)
    * [yq](#yq)
* [Development](#development)
* [Building](#building)

## Usage

*CloudControl* can be used best with docker-compose. Check out the `sample` directory in a flavour for a sample
compose file and to convenience scripts. It includes a small web server written in Go and Vuejs-client dubbed
"CloudControlCenter", which is used as a status screen. It listens to port 8080 inside the container.

Copy the compose file and configure it to your needs. Check below for configuration options per flavour and feature.

Run `init.sh`. This script basically just runs `docker-compose up -d` and tells you the URL for CloudControlCenter.
Open it and wait for CloudControl to finish initializing.

The initialization process will download and configure the additional tools and completes with a message when its done.
It will run each time when the stack is recreated.

After the initialization process you can simply run `docker-compose exec cli /usr/local/bin/cloudcontrol run` to jump
into the running container and work with the installed features.

If you need to change any of the configuration environment variables, rerun the init script afterwards to apply
the changes. Remember, that CloudControl needs to reininitialize for this.

## Using Kubernetes

*CloudControl* is targeted to run on a local machine. It requires the following features to work:

* host path volumes
* host based networking

Some Kubernetes distributions such as [Rancher desktop](https://rancherdesktop.io/) support this and can be used to
run *CloudControl*.

The `sample` directories of each flavour provide an example Kubernetes configuration based on a deployment and a
service. They were preliminary tested on Rancher desktop.

Modify them to your local requirements and then run

    kubectl apply -f k8s.yaml

to apply them.

This will create a new namespace for your project and a deployment and a service in that. Check
`kubectl get -n <project> pod` to watch the progress until a cli pod has been created.

Use `kubectl get -n <project> svc cli` to see the bound ports for the cli service and use your browser to connect
to the *CloudControlCenter* instance.

After the initialization is done, use `kubectl -n <project> exec -it deployment/cli -- /usr/local/bin/cloudcontrol run`
to enter *CloudControl*.

*Warning*: This implementation is currently a preview feature and hasn't been tested thoroughly. It highly depends on
the proper support for host based volumes and networking of the Kubernetes distribution. Please refer to the
documentation and support of your Kubernetes distribution if something isn't working.

## FAQ

### How can I add an informational text for users of CloudControl?

If you want to display a *custom login message* when users enter the container, set environment variable `MOTD`
to that message. If you want to display the default login message as well, also
set the environment variable `MOTD_DISPLAY_DEFAULT` to *yes*.

### How can I forward ports to the host?

If you'd like to forward traffic into a cluster using `kubectl port-forward` you can do the following:

* Add a ports key to the cli-service in your docker-compose file to forward a free port on your host to a defined
port in your container. The docker-compose-files in the sample directories already use port 8081 for this.

* Inside *CloudControl*, check the IP of the container:

```
bash-5.0$ ifconfig eth0
eth0      Link encap:Ethernet  HWaddr 02:42:AC:15:00:02
          inet addr:172.21.0.2  Bcast:172.21.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:53813 errors:0 dropped:0 overruns:0 frame:0
          TX packets:20900 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:75260363 (71.7 MiB)  TX bytes:2691219 (2.5 MiB)
```

* Use the IP address used by the container as the bind address for port-forward to forward traffic
to the previously defined container port to a service on its port (e.g. port 8081 to the
service my-service listening on port 8080):

```
kubectl port-forward --address 172.21.0.2 svc/my-service 8081:8080
```

* Check out, which host port docker bound to the private port you set up (e.g. 8081)

```
docker-compose port cli 8081
```

* Connect to localhost:<host port> on your host

### How to set up command aliases

If you'd like to set up aliases to save some typing, you can use the *run* feature. Run your container with these
environment variables:

* `USE_run=yes`: Set up the run feature
* `RUN_COMMANDS=alias firstalias=command;alias secondalias=command`: Set up some aliases

### How can I share my SSH-keys with the CloudControl container

First, mount your .ssh directory into the container at /home/cloudcontrol/.ssh.

Also, to not enter your passphrase every time you use the key, you should mount the ssh agent socket into the
container and set the environment variable SSH_AUTH_SOCK to that path. CloudControl will automatically fix the
permissions of that file so the CloudControl user can use it.

Here are snippets for your docker-compose file for convenience:

    (...)
    volumes:
        - "<Path to .ssh directory>:/home/cloudcontrol/.ssh"
        # for Linux:
        - "${SSH_AUTH_SOCK}:/ssh-agent"
        # for macOS:
        - "/run/host-services/ssh-auth.sock:/ssh-agent"
    environment:
        - "SSH_AUTH_SOCK=/ssh-agent"

### How to identify Terraform state locks by other CloudControl-users

Because of how CloudControl is designed it uses a defined user named "cloudcontrol", so Terraform state lock
messages look like this:

> Error: Error locking state: Error acquiring the state lock: storage: service returned error: StatusCode=409, ErrorCode=LeaseAlreadyPresent, ErrorMessage=There is already a lease present.
  RequestId:56c21b95-501e-0096-7082-41fa0d000000
  Time:2021-05-05T07:41:25.9164547Z, RequestInitiated=Wed, 05 May 2021 07:41:25 GMT, RequestId=56c21b95-501e-0096-7082-41fa0d000000, API Version=2018-03-28, QueryParameterName=, QueryParameterValue=
  Lock Info:
  ID:        a1cef2cc-fec4-1765-4da8-d068a729ba7e
  Path:      path/terraform.tfstate
  Operation: OperationTypeApply
  Who:       cloudcontrol@5c47a37f920b
  Version:   0.12.17
  Created:   2021-05-05 07:38:01.188897776 +0000 UTC
  Info:

It's hard to identify from that who the other CloudControl user is, that may have opened a lock. The system
user can't be changed, but it's possible to set a better hostname than the one Docker autogenerated.

See this docker-compose snippet on how to set a better hostname:

    version: "3"
    services:
    cli:
    image: "dodevops/cloudcontrol-azure:latest"
    hostname: "<TODO yourname>"
    volumes:
    (...)

If you set hostname in that snippet to "alice", the state lock will look like this now:

> Error: Error locking state: Error acquiring the state lock: storage: service returned error: StatusCode=409, ErrorCode=LeaseAlreadyPresent, ErrorMessage=There is already a lease present.
  RequestId:56c21b95-501e-0096-7082-41fa0d000000
  Time:2021-05-05T07:41:25.9164547Z, RequestInitiated=Wed, 05 May 2021 07:41:25 GMT, RequestId=56c21b95-501e-0096-7082-41fa0d000000, API Version=2018-03-28, QueryParameterName=, QueryParameterValue=
  Lock Info:
  ID:        a1cef2cc-fec4-1765-4da8-d068a729ba7e
  Path:      path/terraform.tfstate
  Operation: OperationTypeApply
  Who:       cloudcontrol@alice
  Version:   0.12.17
  Created:   2021-05-05 07:38:01.188897776 +0000 UTC
  Info:

## Flavours

### aws

Can be used to connect to infrastructure in the AWS cloud. Also see [the AWS CLI documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) for more configuration options.
If you have activated MFA, set AWS_MFA_ARN to the ARN of your MFA device so CloudControl will ask you
for your code.
To start a new session in the CloudControl context, run &#x60;createSession &lt;token&gt;&#x60; afterwards


#### Configuration

* Environment AWS_ACCESS_KEY_ID: Specifies an AWS access key associated with an IAM user or role
* Environment AWS_SECRET_ACCESS_KEY: Specifies the secret key associated with the access key. This is essentially the password for the access key
* Environment AWS_DEFAULT_REGION: Specifies the AWS Region to send the request to
* Environment AWS_MFA_ARN: ARN of the MFA device to use to log in
### azure

Can be used to connect to infrastructure in the Azure cloud. Because we&#x27;re using a container,
a device login will happen, requiring the user to go to a website, enter a code and login.
This only happens once during initialization phase.


#### Configuration

* Environment AZ_SUBSCRIPTION: The Azure subscription to use in this container

## Features

### fish

Installs and configures the [Fish Shell](https://fishshell.com/) with configured [Spacefish theme](https://spacefish.matchai.me/)

#### Configuration

* USE_fish: Enable this feature
* DEBUG_fish: Debug this feature

### azcopy

Installs [AzCopy](https://github.com/Azure/azure-storage-azcopy)

#### Configuration

* USE_azcopy: Enable this feature
* DEBUG_azcopy: Debug this feature

### direnv

Installs [Direnv](https://direnv.net/)

#### Configuration

* USE_direnv: Enable this feature
* DEBUG_direnv: Debug this feature

### helm

Installs [Helm](https://helm.sh)

#### Configuration

* USE_helm: Enable this feature
* DEBUG_helm: Debug this feature
* Environment HELM_VERSION: Valid Helm version to install (e.g. 1.5.4)

### jq

Installs the [JSON parser and processor jq](https://stedolan.github.io/jq/)

#### Configuration

* USE_jq: Enable this feature
* DEBUG_jq: Debug this feature

### kc

Installs [kc](https://github.com/dodevops/cloudcontrol/blob/master/feature/kc/kc.sh), a quick context switcher for kubernetes.


#### Configuration

* USE_kc: Enable this feature
* DEBUG_kc: Debug this feature

### kubectlnodeshell

Installs [kubectl node-shell](https://github.com/kvaps/kubectl-node-shell)

#### Configuration

* USE_kubectlnodeshell: Enable this feature
* DEBUG_kubectlnodeshell: Debug this feature

### kubernetes

Installs and configures [kubernetes](https://kubernetes.io/docs/reference/kubectl/overview/) with [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) to connect to the flavour&#x27;s kubernetes clusters

#### Configuration

* USE_kubernetes: Enable this feature
* DEBUG_kubernetes: Debug this feature
* (azure flavour) Environment AZ_K8S_CLUSTERS: A comma separated list of AKS clusters to manage
inside *CloudControl* (only for azure flavour).
Each cluster is a pair of resource group and cluster name, separated by a colon. Optionally, you can specify
the target subscription.
For example: myresourcegroup:myk8s,myotherresourcegroup@othersubscription:mysecondk8s will install myk8s from
the myresourcegroup resource group and mysecondk8s from the resource group myotherresourcegroup in the
subscription othersubscription.
Prefix a cluster name with an ! to load the admin-credentials for that cluster instead of the user credentials.

* (aws flavour) Environment AWS_K8S_CLUSTERS: A comma separated list of EKS clusters to manage
inside *CloudControl* (only for aws flavour).
For each cluster give the cluster name. If you need to assume an ARN role, add that to the clustername
with an additional | added.
For example: myekscluster|arn:aws:iam::32487234892:sample/sample

If you additionally need to assume a role before fetching the EKS credentials, add the role, prefixed with
an @:
myekscluster|arn:aws:iam::4327849324:sample/sample@arn:aws:iam::specialrole

* (aws flavour) Environment AWS_SKIP_GPG: If set, skips the gpg checks for the yum repo of kubectl,
as [this](https://github.com/kubernetes/kubernetes/issues/37922)
[sometimes](https://github.com/kubernetes/kubernetes/issues/60134)
seems to fail.


### packages

Installs additional packages into the container

#### Configuration

* USE_packages: Enable this feature
* DEBUG_packages: Debug this feature
* Environment PACKAGES: A whitespace separated list of packages to install. The packages will be installed with the flavour&#x27;s default package manager.


### packer

Installs [Packer](https://packer.io)

#### Configuration

* USE_packer: Enable this feature
* DEBUG_packer: Debug this feature
* Environment PACKER_VERSION: Valid Packer version to install (e.g. 1.5.4)

### run

Runs commands inside the shell when entering the cloud control container

#### Configuration

* USE_run: Enable this feature
* DEBUG_run: Debug this feature
* Environment RUN_COMMANDS: Valid shell commands to run

### stern

Installs [stern](https://github.com/wercker/stern), a multi pod and container log tailing for Kubernetes


#### Configuration

* USE_stern: Enable this feature
* DEBUG_stern: Debug this feature
* Environment STERN_VERSION: Valid Stern version (e.g. 1.11.0)

### terraform

Installs and configures [Terraform](https://terraform.io)

#### Configuration

* USE_terraform: Enable this feature
* DEBUG_terraform: Debug this feature
* Volume-target /terraform: Your local terraform base directory
* Volume-target /credentials.terraform: A Terraform variable file holding sensitive information when working with terraform (e.g. Terraform app secrets, etc.)
* Environment TERRAFORM_VERSION: A valid terraform version to install (e.g. 0.12.17)

### terragrunt

Installs [Terragrunt](https://github.com/gruntwork-io/terragrunt)

#### Configuration

* USE_terragrunt: Enable this feature
* DEBUG_terragrunt: Debug this feature
* Environment TERRAGRUNT_VERSION: Valid version of terragrunt to install

### timezone

Configures the container&#x27;s timezone

#### Configuration

* USE_timezone: Enable this feature
* DEBUG_timezone: Debug this feature
* Environment TZ: The timezone to use

### velero

Installs the [Velero](https://velero.io) kubernetes backup CLI

#### Configuration

* USE_velero: Enable this feature
* DEBUG_velero: Debug this feature
* Environment VELERO_VERSION: Valid velero version to install (e.g. v1.4.2)

### vim

Installs [Vim](https://www.vim.org/)

#### Configuration

* USE_vim: Enable this feature
* DEBUG_vim: Debug this feature

### yq

Installs the [YAML parser and processor yq](https://github.com/mikefarah/yq)

#### Configuration

* USE_yq: Enable this feature
* DEBUG_yq: Debug this feature
* Environment YQ_VERSION: Valid YQ version to install (e.g. 4.5.0)


## Development

*CloudControl* supports a decoupled development of features and flavours. If you're missing something, just fork this
repository, create a subfolder for your new feature under "features" and add these files:

* feature.yaml: A descriptor for your feature with a title, a description and configuration notes
* install.sh: A shell script that is run by CloudControlCenter and should install everything you need
  for your new feature
* motd.sh: (optional) If you want to show some information to the users upon login, put them here.

If you need another flavour (aka cloud provider), add a new subdirectory under "flavour" and add a flavour.yaml describing
your flavour the same way as a feature. For the rest of the files, please check out existing flavours for details. Please,
include a sample configuration for your flavour to make it easier for other people to work with it.

### Installer utilities

In your install script, you can source the utils library

    . /feature-installer-utils.sh

#### execHandle

Installation scripts usually echo out some kind of progress, execute something and have to check for errors. The command
`execHandle` does all this in a one liner:

    execHandle "Progress message" command

This will print out "Progress message...", run the command and if it exits with a non-zero status code, it will print
the output of the command and exit with status code 1.

Using this makes installer script way shorter and easier to maintain.

## Building

Build a flavor container image with the base of the repository as the build context like this:

    build.sh <tag> <flavour>

To build all flavours with the same tag, use

    build.sh <tag>
