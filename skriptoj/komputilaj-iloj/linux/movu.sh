#!/bin/bash

malnova_loko="$1"
nova_loko="$2"

echo "malnova-loko: $malnova_loko"
ls -la "$malnova_loko"

echo
echo "nova-loko: $nova_loko"
ls -la "$nova_loko" 2>/dev/null || echo "(dosierejo ne ekzistas ankoraŭ)"

echo
read -p "Daŭrigi? (j/n) " konf
[ "$konf" != "j" ] && echo "Nuligita." && exit 1

mkdir -p "$nova_loko"
mv "$malnova_loko"/* "$nova_loko"/ 2>/dev/null

rm -rf "$malnova_loko"
ln -s "$nova_loko" "$malnova_loko"

echo "Farite."
ls -l "$malnova_loko"

