#!/usr/bin/env bash
# Vide (toutes versions) puis supprime un bucket S3 versionné.
#   Usage : delete-bucket.sh <bucket> <force_destroy:true|false>
# Appelé par le provisioner de destruction quand le bucket est géré via l'AWS CLI.
set -euo pipefail
BUCKET="$1"
FORCE="${2:-false}"

aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null || { echo "Bucket $BUCKET absent"; exit 0; }

if [[ "$FORCE" == "true" ]]; then
  for kind in Versions DeleteMarkers; do
    while :; do
      batch="$(aws s3api list-object-versions --bucket "$BUCKET" --max-items 500 \
        --query "{Objects: ${kind}[].{Key:Key,VersionId:VersionId}}" --output json)"
      echo "$batch" | grep -q '"Key"' || break
      aws s3api delete-objects --bucket "$BUCKET" --delete "$batch" >/dev/null
    done
  done
fi

aws s3api delete-bucket --bucket "$BUCKET"
echo "Bucket $BUCKET supprimé"
