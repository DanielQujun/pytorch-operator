#!/usr/bin/env bash

# Copyright 2019 The Kubeflow Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

SWAGGER_JAR_URL="http://search.maven.org/maven2/io/swagger/swagger-codegen-cli/2.4.6/swagger-codegen-cli-2.4.6.jar"
SWAGGER_CODEGEN_JAR="hack/python-sdk/swagger-codegen-cli.jar"
SWAGGER_CODEGEN_CONF="hack/python-sdk/swagger_config.json"
SWAGGER_CODEGEN_FILE="pkg/apis/pytorch/v1/swagger.json"
SDK_OUTPUT_PATH="sdk/python"

if [ -z "${GOPATH:-}" ]; then
    export GOPATH=$(go env GOPATH)
fi

# Grab kube-openapi version from go.sum
OPENAPI_VERSION=$(grep 'k8s.io/kube-openapi' go.sum | awk '{print $2}' | head -1)
OPENAPI_PKG=$(echo `go env GOPATH`"/pkg/mod/k8s.io/kube-openapi@${OPENAPI_VERSION}")

if [[ ! -d ${OPENAPI_PKG} ]]; then
    echo "${OPENAPI_PKG} is missing. Running 'go mod download'."
    go mod download
fi

echo ">> Using ${OPENAPI_PKG}"

echo "Building openapi-gen"
go build -o openapi-gen ${OPENAPI_PKG}/cmd/openapi-gen

echo "Generating OpenAPI specification ..."
./openapi-gen --input-dirs github.com/kubeflow/pytorch-operator/pkg/apis/pytorch/v1 --output-package github.com/kubeflow/pytorch-operator/pkg/apis/pytorch/v1 --go-header-file hack/boilerplate/boilerplate.go.txt

echo "Generating swagger file ..."
go run hack/python-sdk/main.go 0.1 > ${SWAGGER_CODEGEN_FILE}

echo "Downloading the swagger-codegen JAR package ..."
wget -O ${SWAGGER_CODEGEN_JAR} ${SWAGGER_JAR_URL}

echo "Generating Python SDK for Kubeflow PyTorch-Operator ..."
java -jar ${SWAGGER_CODEGEN_JAR} generate -i ${SWAGGER_CODEGEN_FILE} -l python -o ${SDK_OUTPUT_PATH} -c ${SWAGGER_CODEGEN_CONF}

echo "Kubeflow PyTorch Operator Python SDK is generated successfully to folder ${SDK_OUTPUT_PATH}/."
