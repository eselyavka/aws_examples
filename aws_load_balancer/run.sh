#!/bin/bash
set -Cvex

NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NUMBER_OF_ATTEMPTS=10
NUMBER_OF_PROBES=120

function print_error_and_exit() {
    local body="${1}"
    printf "${RED}FAIL:${NC} ${body}\n"
    exit 1
}

function log() {
    local body="${1}"
    printf "${GREEN}INFO:${NC} ${body}\n"
}

function create_stack() {
    local template="${1}"
    local params="${2}"
    local stack_name="${3}"
    local public_ip_a

    aws --region us-east-1 \
        cloudformation create-stack \
        --stack-name "${stack_name}" \
        --template-body "${template}" \
        --parameters "${params}" &>/dev/null || print_error_and_exit "can't create stack=${stack_name}"

    aws cloudformation wait stack-create-complete --stack-name "${stack_name}" &>/dev/null

    public_ip_a="$(aws ec2 describe-instances \
                   --filters 'Name=instance-state-name,Values=running' \
                   'Name=tag:Name,Values=A' \
                   --query 'Reservations[*].Instances[*].PublicIpAddress' \
                   --output=text 2>/dev/null)"

    echo "${public_ip_a}"
}

function balancer_probe() {
    local public_ip_a="${1}"
    local probe_num="${2}"
    local http_code

    set -e
    http_code="$(curl -s -m10 -w '%{http_code}' -o/dev/null -XGET --retry 5 http://${public_ip_a}/helloz)"
    set +e

    if [[ "${http_code}" -eq "200" ]] ; then
        return 0
    fi

    if [[ "${probe_num}" -gt "${NUMBER_OF_PROBES}" ]] ; then
        return 1
    fi

    sleep 1

    balancer_probe "${public_ip_a}" "$((probe_num + 1))"
}

function check_availability() {
    local public_ip_a="${1}"
    local expected="${2}"
    local i
    declare -a responces
    local actual

    balancer_probe "${public_ip_a}" 0 || print_error_and_exit "balancer with ip=${public_ip_a} not ready"

    set -e
    for i in {0..20} ; do 
        responces+=( "$(curl -s -m10 -o/dev/stdout -XGET --retry 5 http://${public_ip_a}/helloz)" )
        sleep 0.5
    done
    set +e

    actual="$(tr ' ' '\n' <<<"${responces[*]}" | sort | uniq | wc -l)"

    [[ "${actual}" -eq "${expected}" ]] || print_error_and_exit "actual=${actual}, expected=${expected}"

    log 'TEST PASSED'
}

function server_action() {
    local srv="${1}"
    local action="${2}"
    local aws_mapping='start-instances'
    local filter_state='stopped'

    if [[ "${action}" = 'stop' ]] ; then
        aws_mapping='stop-instances'
        filter_state='running'
    fi

    local instance="$(aws ec2 describe-instances \
                      --filters "Name=instance-state-name,Values=${filter_state}" \
                      "Name=tag:Name,Values=${srv}" \
                      --query 'Reservations[*].Instances[*].InstanceId' \
                      --output=text)"

    log "perform '${action}' on instance=${instance}"

    aws ec2 ${aws_mapping} --instance-ids "${instance}" || print_error_and_exit "can't perform ${action} instance=${instance}"

    check_status 'none' "${instance}" 0 || print_error_and_exit "instance=${instance} is not running"

    log "${instance} successfully ${action}"
}

function check_status() {
    local _status="${1}"
    local instance="${2}"
    local attempt="${3}"

    if [[ "${_status}" = "running" ]] || [[ "${_status}" = "stopped" ]] ; then
        return 0
    fi

    if [[ "${attempt}" -gt "${NUMBER_OF_ATTEMPTS}" ]] ; then
        return 1
    fi

    curr_stat="$(aws ec2 describe-instances \
                 --instance-id "${instance}" \
                 --query 'Reservations[*].Instances[*].State.Name' \
                 --output text)"

    sleep 30

    check_status "${curr_stat}" "${instance}" "$((attempt + 1))"
}

function main() {
    local template="${1:-file://cf.json}"
    local params="${2:-file://parameters.json}"
    local stack_name="${3:-abc}"
    local public_ip_a

    public_ip_a="$(create_stack "${template}" "${params}" "${stack_name}")"

    [[ -z "${public_ip_a}" ]] && print_error_and_exit "can't obtain public IP"

    check_availability "${public_ip_a}" "2"

    server_action "B" "stop"

    check_availability "${public_ip_a}" "1"

    server_action "B" "start"

    check_availability "${public_ip_a}" "2"

    server_action "C" "stop"

    check_availability "${public_ip_a}" "1"

    server_action "C" "start"

    check_availability "${public_ip_a}" "2"
}

main "${1}" "${2}" "${3}"
