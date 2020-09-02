cat <<EOT >> ~/.bashrc
alias hist="history | cut -c 8-"
alias k="kubectl"
alias kg="kubectl get"
alias kga="kubectl get all"
alias kcre="kubectl create"
alias kapp="kubectl apply"
alias kdel="kubectl delete"
alias kdes="kubectl describe"
alias klogs="kubectl logs"
alias watchk="watch -d kubectl get all"
source <(kubectl completion bash)
EOT

