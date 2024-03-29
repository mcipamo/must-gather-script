#!/bin/bash
#Require data
# must-gather collector script
# By Milton Cipamocha
# Red Hat Certified Architect
# Senior Technical Support Engineer MCS
clear
echo "========================================================"
echo "=        Welcome to the must-gather collector          ="
echo "========================================================"

read -r -p "Enter Customer ClusterID: " cid
read -r -p "Enter your user, with the format: rhn-support-xxxx: " user
read -r -p "Enter your case number: " case

echo "Welcome!" $user
sleep 3
clear
#OCM Login
ocm backplane login $cid 2> /dev/null 

#Cluster name description
CLUSTER=$(ocm describe cluster $cid |grep  Name |grep -v Display |awk '{print $2}')

echo "===================================================================================="
echo "= Hey," $user "you are logged in the cluster: " $CLUSTER                         " ="
echo "===================================================================================="
sleep 5

#Generate token

curl -u $user https://access.redhat.com/hydra/rest/v1/sftp/token/upload/temporary > $HOME/temporal.txt 
TOKEN=$(cat $HOME/temporal.txt |grep token |awk '{print $3}' |sed 's/"//' |sed 's/"//' |sed 's/,//')
#echo $TOKEN
clear

#Create secret
echo "Creating secret"
sleep 3
oc create secret generic case-management-creds --from-literal=username=$user --from-literal=password=$TOKEN -n openshift-must-gather-operator 
sleep 3

#Add case in file
cat<<-EOF>must-gather.yaml
apiVersion: managed.openshift.io/v1alpha1
kind: MustGather
metadata:
  name: $case-mustgather       ## must-gather name
  namespace: openshift-must-gather-operator
spec:
  caseID: '$case'               ## Here placed caseID
  caseManagementAccountSecretRef:
    name: case-management-creds
  serviceAccountRef:
    name: must-gather-admin
  internalUser: true 
EOF

#Check must-gather file
echo "=========================================================="
echo "=          This is your must-gather manifest:            ="
echo "=========================================================="
cat  must-gather.yaml

read -p "Press enter to continue"

clear
#Creating must-gather pods
echo "=========================================================="
echo "=           Deploying must-gather pod                    ="
echo "=========================================================="
oc apply -f must-gather.yaml -n openshift-must-gather-operator

rm $HOME/temporal.txt

sleep 10

#Check pods
checkpods()
{
count=1
while true; do oc get pods -n openshift-must-gather-operator |grep -v operator; sleep 2;  if [ $count -eq 5 ]; then echo "finish"; break; fi; (( count++ )); done
}

#Check logs from gather

checklogs()
{
count=1
POD_NAME=$(oc get pods -n openshift-must-gather-operator |grep -i mustgather |awk '{print $1}')
while true; do oc logs $POD_NAME -n openshift-must-gather-operator -c gather-0; sleep 2; if [ $count -eq 5 ]; then echo "finish"; break; fi; (( count++ )); done
}

checkpods
checklogs

rm $HOME/must-gather.yaml
