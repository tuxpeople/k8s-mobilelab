#!/usr/bin/env bash

BASEDIR=$(git rev-parse --show-toplevel)
FILE="${BASEDIR}/cluster/core/kubelet-serving-cert-approver/patched-standalone-install.yaml"

echo "# yamllint disable rule:indentation" > ${FILE}
curl -sL https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/main/deploy/standalone-install.yaml | grep -v pod-security.kubernetes.io >> ${FILE}
