for h in $(curl scrapi.org/search/$1 | jq -r '.collection.items[].href'); do curl -O $(curl $h | jq -r '.currentImage.imageUrl'); done
# curl scrapi.org/search/$1 | jq -r '.collection.items[].href' | while read h; do curl -O $(curl $h | jq -r '.currentImage.imageUrl'); done
