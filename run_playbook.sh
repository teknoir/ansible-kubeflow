#!/bin/bash
set -xeo pipefail

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -l|--limit)
    LIMIT="$2"
    shift # past argument
    shift # past value
    ;;
    -r|--repo)
    REPO="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--playbook)
    PLAYBOOK="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help|*)
    echo "$0 -r(--repo) <repo url> -p(--playbook) <path to playbook in repo> -l(--limit) <ansible limit string>"
    echo "\nExample:"
    echo "$0 --repo https://github.com/teknoir/device-patch-base.git --playbook example/patch_device_example.yaml --limit 'hardware_raspberry_pi,!patch_version_verified'"
    echo ""
    echo ""
    exit 0
    ;;
esac
done

DEVICES=( $(ansible --list-hosts all --limit ${LIMIT} | awk 'NR>1') )
TUNNELS_CREATED=false

for DEVICE in ${DEVICES} ; do
  TUNNEL_PORT="$(kubectl get device $DEVICE -o jsonpath='{.spec.keys.data.tunnel}' | base64 -d)"
  RE='^[0-9]+$'
  if ! [[ $TUNNEL_PORT =~ $RE ]] ; then
    echo "Enabling reverse tunnel for: ${DEVICE}"
    TUNNEL_PORT="$(( ( RANDOM % 64511 )  + 1024 ))"
    TUNNEL_PORT_B64=$(echo -ne "${TUNNEL_PORT}" | base64)
    kubectl patch device ${DEVICE} \
      --type merge \
      -p "{\"spec\":{\"keys\":{\"data\":{\"tunnel\":\"${TUNNEL_PORT_B64}\"}}}}"
    TUNNELS_CREATED=true
  else
    echo "Reverse tunnel already enabled for: ${DEVICE}"
  fi
done

if [[ $TUNNELS_CREATED = true ]] ; then
    echo "Wait 5 minutes for reverse tunnels to establish"
    sleep 5m
fi

echo "Clone git repo: ${REPO}"
git clone ${REPO} ./playbook_repo

echo "Run playbook: ${PLAYBOOK}"
ansible-playbook -vvv ./playbook_repo/${PLAYBOOK} --limit ${LIMIT} || true

for DEVICE in ${DEVICES} ; do
  echo "Disabling tunnel for ${DEVICE}"
  kubectl patch device ${DEVICE} \
    --type merge \
    -p "{\"spec\":{\"keys\":{\"data\":{\"tunnel\":\"TkE=\"}}}}"
done
