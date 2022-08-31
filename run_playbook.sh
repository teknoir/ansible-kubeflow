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
    echo "$0 --repo https://github.com/teknoir/device-patch-base.git --playbook example/patch_device_example.yaml --limit 'hardware=nvidia-jetson-nano-b00,patch_version notin (verified)'"
    echo ""
    echo ""
    exit 0
    ;;
esac
done

DEVICES=$(kubectl -l "${LIMIT}" get device -o name)

for DEVICE in ${DEVICES} ; do
  echo "Enabling tunnel for: ${DEVICE}"
  TUNNEL_PORT="$(kubectl get $DEVICE -o jsonpath='{.spec.keys.data.tunnel}' | base64 -d)"
  re='^[0-9]+$'
  if ! [[ $TUNNEL_PORT =~ $re ]] ; then
    TUNNEL_PORT="$(( ( RANDOM % 64511 )  + 1024 ))"
    TUNNEL_PORT_B64=$(echo -ne "${TUNNEL_PORT}" | base64)
    kubectl patch ${DEVICE} \
      --type merge \
      -p "{\"spec\":{\"keys\":{\"data\":{\"tunnel\":\"${TUNNEL_PORT_B64}\"}}}}"
  fi
done

echo "Sleep 5 minutes for reverse tunnels to establish"
sleep 5m

echo "Clone playbook repo: ${REPO}"
git clone ${REPO} ./playbook_repo

echo "Run playbook playbook_repo/${PLAYBOOK}"
ansible-playbook -v playbook_repo/${PLAYBOOK} --limit "${LIMIT}" || true


for DEVICE in ${DEVICES} ; do
  echo "Disabling tunnel for ${DEVICE}"
  kubectl patch ${DEVICE} \
    --type merge \
    -p "{\"spec\":{\"keys\":{\"data\":{\"tunnel\":\"TkE=\"}}}}"
done
