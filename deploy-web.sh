#!/bin/bash
set -e

# Make sure to create the ./deploy folder and initialize the git repository

flutter build web --release
rm -R deploy/*
cp -R build/web/* deploy/
cd deploy

git add --all .
git commit -m "Deployment"
git push