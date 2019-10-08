namespace=$1
pod_to_kill=$2

if [ "$2" == "all" ]; then
  pods=`kubectl get pods -n $namespace | grep Running | awk '{print $1}'`
else
  pods=`kubectl get pods -n $namespace $pod_to_kill | grep -v NAME | awk '{print $1}'`
fi

for pod in $pods; do
  pod_id=`kubectl get pod -n $namespace $pod -o jsonpath='{.status.containerStatuses[].containerID}' | cut -d '/' -f3;`
  node=`kubectl get pod -n $namespace $pod -o wide | awk '/node/ {print $7}'`
  node_ip=`kubectl get node -o wide $node | awk '/node/ {print $7}'`
  shim_pid=$(ssh -i /home/ubuntu/.ssh/openstack_tmp -o StrictHostKeyChecking=no ubuntu@$node_ip "ps aux | grep $pod_id | grep -v grep | awk '{print \$2}'")
  echo "Pod name: $pod"
  echo "Pod ID: $pod_id"
  echo "Node name: $node"
  echo "Node ip: $node_ip"
  echo "containerd-shim process ID: $shim_pid"
  echo ""
  if [ "$3" == "kill" ]; then
    ssh -i /home/ubuntu/.ssh/openstack_tmp -o StrictHostKeyChecking=no ubuntu@$node_ip "sudo kill -9 $shim_pid"
    echo "process $shim_pid for pod $pod is killed"
  fi
done
