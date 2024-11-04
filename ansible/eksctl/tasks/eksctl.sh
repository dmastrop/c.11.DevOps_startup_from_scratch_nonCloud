#!/usr/bin/env bash
export KUBECONFIG=~/.kube/eksctl_ansible/config
eksctl create cluster -f /home/ubuntu/course11_devops_startup/ansible/eksctl/tasks/cluster_ansible.yaml
