#!/usr/bin/env bash

gleam run -m lustre/dev build app

mkdir -p prod/priv/static

cp ./build/dev/javascript/lustre_ui/priv/static/lustre-ui.css prod/priv/static/lustre-ui.css

cp ./priv/static/sock_calculator.mjs prod/priv/static/sock_calculator.mjs
cp ./priv/static/index.css prod/priv/static/index.css

cp index.html prod/index.html

sed -i '' 's/\.\/build\/dev\/javascript\/lustre_ui/\./g' prod/index.html
