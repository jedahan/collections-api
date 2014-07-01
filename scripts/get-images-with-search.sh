# grab a list of images with a single search term
hrefs=$(curl -s scrapi.org/search/$1 | jq -r '.collection.items[].href')

for href in $hrefs; do
  echo "Getting $href"
  imageUrl=$(curl -s $href | jq -r '.currentImage.imageUrl')
  curl -sO $imageUrl
done
