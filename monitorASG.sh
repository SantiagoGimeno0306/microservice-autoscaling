ASG="terraform-20260307115916362000000007"

for id in $(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $ASG \
  --query "AutoScalingGroups[0].Instances[].InstanceId" \
  --output text); do

  cpu=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=$id \
    --statistics Average \
    --period 60 \
    --start-time $(date -u -d "5 minutes ago" +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --query "Datapoints[-1].Average" \
    --output text)

  echo "$id CPU: $cpu %"

done