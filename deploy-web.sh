mkdir -p deploy

flutter build web --release
rm -R deploy/*
cp -R build/web/* deploy/
cd deploy

git add --all .
git commit -m "Deployment"
git push