#!/usr/bin/env sh

service docker start
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
curl -Lo kyma.tar.gz "https://github.com/kyma-project/cli/releases/download/$(curl -s https://api.github.com/repos/kyma-project/cli/releases/latest | grep tag_name | cut -d '"' -f 4)/kyma_Linux_x86_64.tar.gz" && mkdir kyma-release && tar -C kyma-release -zxvf kyma.tar.gz && chmod +x kyma-release/kyma && rm -rf kyma.tar.gz
kyma-release/kyma provision k3d
kubectl cluster-info
kyma-release/kyma deploy --ci --components-file tests/components/application-connector/resources/installation-config/mini-kyma-skr.yaml --source local --workspace $PWD
cd tests/components/application-connector

echo "----------HERE----------"
kubectl run --image curlimages/curl -i --rm experiment1 -- curl oauth2.mps.dev.kyma.cloud.sap
echo "----------HERE----------"
kubectl apply -f resources/patches/coredns.yaml
echo "----------HERE----------"
kubectl run --image curlimages/curl -i --rm experiment2 -- curl oauth2.mps.dev.kyma.cloud.sap
echo "----------HERE----------"

make -f Makefile.test-compass-runtime-agent test-compass-runtime-agent

echo "----------HERE----------"
kubectl run --image curlimages/curl -i --rm experiment3 -- curl oauth2.mps.dev.kyma.cloud.sap
echo "----------HERE----------"

failed=$?
k3d cluster delete kyma
exit $failed
