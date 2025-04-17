#!/usr/bin/env bash

yarn init -y
yarn set version berry
yarn plugin import typescript
yarn add -D typescript tslint @types/express
yarn add express

tsc --init
yarn tslint --init

echo '{
  "defaultSeverity": "error",
  "extends": ["tslint:recommended"],
  "jsRules": {},
  "rules": {
    "no-console": false
  },
  "rulesDirectory": []
}' > tslint.json

nvim package.json

mkdir src

touch src/index.ts

