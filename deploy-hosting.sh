#!/bin/bash
# Publica index.html (desde el repositorio) en Firebase Hosting: inspeccion-rollos.web.app
SITE=inspeccion-rollos
PROJ=inspeccion-rollos
API=https://firebasehosting.googleapis.com/v1beta1
RAW=https://raw.githubusercontent.com/10gonzaleztrejo-Texas/10gonzaleztrejo-Texas.github.io/main/index.html
T=$(gcloud auth print-access-token)
mkdir -p ~/rollosapp && cd ~/rollosapp
curl -sL -o index.html "$RAW"
echo "archivo=$(wc -c < index.html) bytes"
curl -s -X POST -H "Authorization: Bearer $T" -H "Content-Type: application/json" \
  -d '{}' "$API/projects/$PROJ/sites?siteId=$SITE" > /tmp/site.json
gzip -c -n index.html > index.html.gz
H=$(sha256sum index.html.gz | cut -d' ' -f1)
V=$(curl -s -X POST -H "Authorization: Bearer $T" -H "Content-Type: application/json" -d '{}' "$API/sites/$SITE/versions" | jq -r .name)
echo "version=$V"
U=$(curl -s -X POST -H "Authorization: Bearer $T" -H "Content-Type: application/json" \
  -d "{\"files\":{\"/index.html\":\"$H\"}}" "$API/$V:populateFiles" | jq -r .uploadUrl)
curl -s -X POST -H "Authorization: Bearer $T" -H "Content-Type: application/octet-stream" \
  --data-binary @index.html.gz "$U/$H" -o /dev/null -w "subida=%{http_code}\n"
curl -s -X PATCH -H "Authorization: Bearer $T" -H "Content-Type: application/json" \
  -d '{"status":"FINALIZED"}' "$API/$V?update_mask=status" | jq -r '"finalizada="+(.status//"ERROR")'
curl -s -X POST -H "Authorization: Bearer $T" "$API/sites/$SITE/releases?versionName=$V" \
  | jq -r '"publicada="+(.version.status//"ERROR")'
echo "TERMINADO -> https://$SITE.web.app"
