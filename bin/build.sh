#!/usr/bin/env bash

gleam run -m lustre/dev build app

mkdir -p dist/priv/static

cp ./build/dev/javascript/lustre_ui/priv/static/lustre-ui.css dist/priv/static/lustre-ui.css

cp ./priv/static/sock_calculator.mjs dist/priv/static/sock_calculator.mjs
cp ./priv/static/index.css dist/priv/static/index.css

cp index.html dist/index.html

sed -i '' 's/\.\/build\/dev\/javascript\/lustre_ui/\./g' dist/index.html
