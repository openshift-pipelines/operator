

function common_setup() {
  #Step 1 - Create Operator Group
  export KUEUE_NAMESPACE=openshift-kueue-operator
  cat <<EOF | oc apply -f -
  apiVersion: operators.coreos.com/v1
  kind: OperatorGroup
  metadata:
    name: kueue-operator-group
    namespace: $KUEUE_NAMESPACE
  spec: {}
EOF

  #Step 2 - Create Subscription
  cat << EOF > Subscription.yaml
  apiVersion: operators.coreos.com/v1alpha1
  kind: Subscription
  metadata:
    name: kueue-operator
    namespace: $KUEUE_NAMESPACE
  spec:
    channel: stable-v1.3
    installPlanApproval: Automatic
    name: kueue-operator
    source: redhat-operators
    sourceNamespace: openshift-marketplace
EOF
  oc create -f Subscription.yaml


}


