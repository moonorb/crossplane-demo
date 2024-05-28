# The credit goes to Victor Farcic
# This is a modified version from his wonderful tutorial
# https://gist.github.com/vfarcic/732bf76feb51489add89567433019460

#!/usr/bin/env nix-shell
#! nix-shell -i bash

#########################
# Control Plane Cluster #
#########################
# Check if there are any clusters available
if kind get clusters 2>/dev/null | grep -q .; then
    echo "Deleting existing Kind clusters..."
    # If clusters exist, delete them
    kind get clusters | xargs -t -n1 kind delete cluster --name
else
    echo "No Kind clusters found."
fi

kind create cluster

kubectl create namespace test-ns

##############
# Crossplane #
##############

helm upgrade --install crossplane crossplane \
    --repo https://charts.crossplane.io/stable \
    --namespace crossplane-system --create-namespace --wait

kubectl create secret generic aws-creds \
    -n crossplane-system \
    --from-file=creds=credentials/aws-credentials.txt 

kubectl apply -f  providers/provider.yaml 

sleep 30

kubectl apply -f  providerconfigs/providerconfig.yaml

echo "Installation Complete" 

#kubectl apply -f https://raw.githubusercontent.com/moonorb/crossplane-demo/main/providers/provider.yaml
#sleep 30
#kubectl apply -f https://raw.githubusercontent.com/moonorb/crossplane-demo/main/providerconfigs/providerconfig.yaml


