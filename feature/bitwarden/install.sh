. /feature-installer-utils.sh

FLAVOUR="X$(cat /home/cloudcontrol/flavour)X"
if [ "${FLAVOUR}" == "XazureX" ] || [ "${FLAVOUR}" == "XsimpleX" ] || [ "${FLAVOUR}" == "XtanzuX" ]
then
  execHandle "Installing required libraries" sudo apk add nodejs npm
fi

cd ~ || exit 1
execHandle "Installing bitwarden client" npm install @bitwarden/cli
execHandle "Linking bitwarden client" ln -s /home/cloudcontrol/node_modules/.bin/bw bin/bw
