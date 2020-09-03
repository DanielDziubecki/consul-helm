#!/usr/bin/env bats

load _helpers

@test "controller-cert-manager/Deployment: disabled by default" {
  cd `chart_dir`
  assert_empty helm template \
      -s templates/controller-cert-manager-deployment.yaml  \
      .
}

@test "controller-cert-manager/Deployment: enabled with controller.enabled=true" {
  cd `chart_dir`
  local actual=$(helm template \
      -s templates/controller-cert-manager-deployment.yaml  \
      --set 'controller.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# cert secrets

@test "controller-cert-manager/Deployment: no secretName: no tls-{cert,key}-file set" {
  cd `chart_dir`
  local actual=$(helm template \
      -s templates/controller-cert-manager-deployment.yaml  \
      --set 'controller.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-tls-cert-file"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -s templates/controller-cert-manager-deployment.yaml  \
      --set 'controller.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-tls-key-file"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -s templates/controller-cert-manager-deployment.yaml  \
      --set 'controller.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-m-webhook-config-name"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "controller-cert-manager/Deployment: with secretName: tls-{cert,key}-file set" {
  cd `chart_dir`
  local actual=$(helm template \
      -s templates/controller-cert-manager-deployment.yaml  \
      --set 'controller.certs.secretName=foo' \
      --set 'controller.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-tls-cert-file"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -s templates/controller-cert-manager-deployment.yaml  \
      --set 'controller.certs.secretName=foo' \
      --set 'controller.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-tls-key-file"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -s templates/controller-cert-manager-deployment.yaml  \
      --set 'controller.certs.secretName=foo' \
      --set 'controller.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-webhook-name"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "controller-cert-manager/Deployment: Adds certs volumes when controller.certs.secretName is set" {
  cd `chart_dir`
  local actual=$(helm template \
      -s templates/controller-cert-manager-deployment.yaml  \
      --set 'controller.enabled=true' \
      --set 'controller.certs.secretName=foo' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.volumes | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]
}

@test "controller-cert-manager/Deployment: Adds certs volumeMounts when controller.certs.secretName is set" {
  cd `chart_dir`
  local actual=$(helm template \
      -s templates/controller-cert-manager-deployment.yaml  \
      --set 'controller.enabled=true' \
      --set 'controller.certs.secretName=foo' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].volumeMounts | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]
}