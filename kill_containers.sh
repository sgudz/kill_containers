namespace=$1
pod_to_kill=$2
key_path="/home/ubuntu/child_rsa"

if [ "$2" == "all" ]; then
  pods=`kubectl get pods -n $namespace | grep Running | awk '{print $1}'`
else
  pods=`kubectl get pods -n $namespace $pod_to_kill | grep -v NAME | awk '{print $1}'`
fi

for pod in $pods; do
  containers_in_pod=`kubectl get pod -n $namespace $pod | grep Running | awk '{print $2}' | cut -d "/" -f2`
  for i in $(seq 0 $(($containers_in_pod-1))); do
    container_id=`kubectl get pod -n $namespace $pod -o jsonpath="{.status.containerStatuses[$i].containerID}" | cut -d '/' -f3;`
    container_name=`kubectl get pod -n $namespace $pod -o jsonpath="{.status.containerStatuses[$i].name}"`
    node=`kubectl get pod -n $namespace $pod -o wide | awk '/node/ {print $7}'`
    node_ip=`kubectl get node -o wide $node | awk '/node/ {print $7}'`
    shim_pid=$(ssh -i $key_path -o StrictHostKeyChecking=no ubuntu@$node_ip "ps aux | grep $container_id | grep -v grep | awk '{print \$2}'")
    echo "Pod name: $pod"
    echo "Contaiiners in pod: $containers_in_pod"
    echo "Containers name: $container_name"
    echo "Container ID: $container_id"
    echo "Node name: $node"
    echo "Node ip: $node_ip"
    echo "containerd-shim process ID: $shim_pid"
    echo ""
    if [ "$3" == "kill" ]; then
      ssh -i $key_path -o StrictHostKeyChecking=no ubuntu@$node_ip "sudo kill -9 $shim_pid"
      echo "process $shim_pid for container $container_name in $pod pod is killed"
    fi
  done
  echo -e "\e[32m################################################\e[0m"
done
