#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  printf 'Usage: %s /path/to/key.pem PUBLIC_IP\n' "$0" >&2
  exit 1
fi

KEY_PATH="$1"
PUBLIC_IP="$2"

if [[ ! -f "$KEY_PATH" ]]; then
  printf 'Key file not found: %s\n' "$KEY_PATH" >&2
  exit 1
fi

npm run build:ec2

scp -i "$KEY_PATH" -r out ubuntu@"$PUBLIC_IP":/tmp/b6-cloud-out
scp -i "$KEY_PATH" infra/nginx.conf ubuntu@"$PUBLIC_IP":/tmp/b6-cloud-nginx.conf

ssh -i "$KEY_PATH" ubuntu@"$PUBLIC_IP" \
  'sudo apt-get update && sudo apt-get install -y nginx && sudo mkdir -p /var/www/b6-cloud && sudo cp -R /tmp/b6-cloud-out/. /var/www/b6-cloud/ && sudo cp /tmp/b6-cloud-nginx.conf /etc/nginx/sites-available/b6-cloud && sudo ln -sfn /etc/nginx/sites-available/b6-cloud /etc/nginx/sites-enabled/b6-cloud && sudo rm -f /etc/nginx/sites-enabled/default && sudo nginx -t && sudo systemctl enable --now nginx && curl --fail http://localhost/health'

printf '\nDeployment complete. Verify externally:\n'
printf 'curl -i http://%s/health\n' "$PUBLIC_IP"
