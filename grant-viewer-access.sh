#!/bin/bash

# Assign default value to authenticationMode
AUTHENTICATION_MODE="API_AND_CONFIG_MAP"

# Check if the correct number of arguments was provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <cluster-name> <region> <account-number> [authenticationMode]"
    
    exit 1
fi
if [ "$#" -eq 4 ]; then
    AUTHENTICATION_MODE="$4"
fi

# Assign the provided arguments to variables
CLUSTER_NAME="$1"
REGION="$2"
ACCOUNT_NUMBER="$3"


#Create a ClusterRole eks-console-dashboard-full-access-clusterrole and ClusterRoleBinding 
# eks-console-dashboard-full-access-binding with get and list permission for all resources
kubectl apply -f https://s3.us-west-2.amazonaws.com/amazon-eks/docs/eks-console-full-access.yaml

#Update the cluster to allow connections using access-entry
aws eks update-cluster-config --name $CLUSTER_NAME --access-config authenticationMode=$AUTHENTICATION_MODE


echo "Waiting for EKS cluster '$CLUSTER_NAME' in account '$ACCOUNT_NUMBER' and region '$REGION' to become ACTIVE..."

while true; do
    # Get the status of the EKS cluster
    STATUS=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" --query "cluster.status" --output text 2>/dev/null)

    # Check if the command was successful
    if [ $? -eq 0 ]; then
        echo "Current status: $STATUS"
        
        # If the status is ACTIVE, we're done
        if [ "$STATUS" == "ACTIVE" ]; then
            echo "EKS cluster '$CLUSTER_NAME' is active."
            break
        fi
    else
        echo "Failed to get the status of the EKS cluster. Retrying..."
    fi

    # Wait for a bit before trying again
    sleep 10
done

aws eks create-access-entry --cluster-name $CLUSTER_NAME --region "$REGION" --principal-arn arn:aws:iam::$ACCOUNT_NUMBER:role/DoiT-Support-Gateway --type STANDARD --user eks-console-dashboard-full-access-group --kubernetes-groups eks-console-dashboard-full-access-group