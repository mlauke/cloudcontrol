. /feature-installer-utils.sh

if [ "X$(cat /home/cloudcontrol/flavour)X" == "XazureX" ]; then
  for CLUSTER in $(echo "${AZ_K8S_CLUSTERS}" | tr "," "\n"); do
    K8S_RESOURCEGROUP=$(echo "$CLUSTER" | cut -d ":" -f 1)
    K8S_CLUSTER=$(echo "$CLUSTER" | cut -d ":" -f 2)
    K8S_SUBSCRIPTION=()

    if [[ "${K8S_RESOURCEGROUP}" == *"@"* ]]; then
      K8S_SUBSCRIPTION=(--subscription)
      K8S_SUBSCRIPTION+=("$(echo "${K8S_RESOURCEGROUP}" | cut -d "@" -f 2)")
      K8S_RESOURCEGROUP=$(echo "${K8S_RESOURCEGROUP}" | cut -d "@" -f 1)
    fi

    echo -n "Cluster ${K8S_CLUSTER} in resource group ${K8S_RESOURCEGROUP}"

    ADMIN_PARAMETER=""

    if [ "X${K8S_CLUSTER:0:1}X" == "X!X" ]; then
      ADMIN_PARAMETER="--admin"
      K8S_CLUSTER="${K8S_CLUSTER:1}"
      echo -n "as admin"
    fi

    echo

    execHandle "Fetching k8s credentials for ${CLUSTER}" az aks get-credentials --resource-group "${K8S_RESOURCEGROUP}" --name "${K8S_CLUSTER}" ${ADMIN_PARAMETER} "${K8S_SUBSCRIPTION[@]}"
  done

  execHandle "Installing kubectl" sudo az aks install-cli
elif [ "X$(cat /home/cloudcontrol/flavour)X" == "XawsX" ]
then
  waitForMfaCode
  for CLUSTER in $(echo "${AWS_K8S_CLUSTERS}" | tr "," "\n")
  do
    ARN_OPTION=()
    K8S_CLUSTER=""
    SUDO_OPTION=()
    if echo "$CLUSTER" | grep "|.*@" &>/dev/null
    then
      K8S_CLUSTER=$(echo "$CLUSTER" | cut -d "|" -f 1)
      ARN=$(echo "$CLUSTER" | cut -d "|" -f 2 | cut -d "@" -f 1)
      SUDO_ARN=$(echo "$CLUSTER" | cut -d "|" -f 2 | cut -d "@" -f 2)
      ARN_OPTION=(--role-arn "${ARN}")
      SUDO_OPTION=(awsudo "${SUDO_ARN}")
      echo "Cluster ${K8S_CLUSTER} with role ${ARN} as role ${SUDO_ARN}"
    elif echo "$CLUSTER" | grep "|" &>/dev/null
    then
      K8S_CLUSTER=$(echo "$CLUSTER" | cut -d "|" -f 1)
      ARN=$(echo "$CLUSTER" | cut -d "|" -f 2)
      ARN_OPTION=(--role-arn "${ARN}")
      echo "Cluster ${K8S_CLUSTER} with role ${ARN}"
    else
      K8S_CLUSTER="$CLUSTER"
      echo "Cluster ${K8S_CLUSTER}"
    fi
    execHandle "Fetching k8s credentials for ${CLUSTER}" "${SUDO_OPTION[@]}" aws eks update-kubeconfig --name "${K8S_CLUSTER}" --alias "${K8S_CLUSTER}" "${ARN_OPTION[@]}"
  done

  TEMPFILE=$(mktemp)
  GPGCHECK=1

  if [ -n "${AWS_SKIP_GPG}" ];
  then
    GPGCHECK=0
  fi

  cat <<EOF > "${TEMPFILE}"
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=${GPGCHECK}
repo_gpgcheck=${GPGCHECK}
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

  execHandle "Configuring package repository for kubectl" sudo mv "${TEMPFILE}" /etc/yum.repos.d/kubernetes.repo

  execHandle "Installing kubectl..." sudo yum install -y kubectl
elif [ "X$(cat /home/cloudcontrol/flavour)X" == "XsimpleX" ]
then
  TEMPDIR=$(mktemp -d)
  cd "${TEMPDIR}" || exit
  execHandle "Downloading kubectl" curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION:-$(curl -L -s https://dl.k8s.io/release/stable.txt)}/bin/linux/amd64/kubectl"
  execHandle "Making kubectl executable" chmod +x kubectl
  execHandle "Moving kubectl to bin" mv kubectl /home/cloudcontrol/bin
  cd - &>/dev/null || exit
  rm -rf "${TEMPDIR}"
fi
