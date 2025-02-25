#!/usr/bin/env bash

. /feature-installer-utils.sh

if [ -n "${AWS_MFA_ARN}" ]
then
  execHandle "Installing jq" sudo yum install -y jq
  cat <<EOF >>~/.bashrc
ORIGINAL_AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ORIGINAL_AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
alias createSession="source ~/bin/createSession.bash"

if [ -n "\${SSH_AUTH_SOCK}" ] && [ -e "\${SSH_AUTH_SOCK}" ]
then
  sudo /bin/chmod 0777 \${SSH_AUTH_SOCK}
fi
EOF
else
  echo "AWS initialized"
fi

