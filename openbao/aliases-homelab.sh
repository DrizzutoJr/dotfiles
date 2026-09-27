_bao_login() {
  local addr="$1"
  local instance="$2"
  shift 2

  BAO_CACERT="$(host_config bao_cacert)" || return 1
  export BAO_CACERT
  export BAO_ADDR="$addr"
  export BAO_INSTANCE="$instance"

  local username
  username="$(host_config username)" || return 1
  echo "Authenticating to $BAO_INSTANCE"
  if [[ $# -eq 2 ]]; then
    export BAO_NAMESPACE="$1"
    username="$2"
  elif [[ $# -eq 1 ]]; then
    export BAO_NAMESPACE="$1"
  fi
  if [[ -n "$BAO_NAMESPACE" ]]; then
    echo "Using namespace $BAO_NAMESPACE"
  fi
  bao login -method=userpass -path=ops-userpass username="$username"
}

bao_prod() {
  _bao_login "https://openbao.prod.homelab" "prod.homelab" "$@"
}
alias bao-prod=bao_prod

bao_dev() {
  _bao_login "https://openbao.dev.homelab" "dev.homelab" "$@"
}
alias bao-dev=bao_dev
