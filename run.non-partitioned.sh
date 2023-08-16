trap printout SIGINT
printout() {
    [[ ! -z "$CONSUMER_PID" ]] && echo "\nExiting... Killing Consumer" && kill -15 $CONSUMER_PID
    exit
}

TOPIC="test-non-partitioned-0"

echo "\n\nSTEP_1::DATA PREPARATION\n\n" && sleep 3
echo "Creating topic $TOPIC"
kubectl exec --namespace pulsar -t pulsar-toolset-0 -- bin/pulsar-admin topics create $TOPIC
echo "Setting retention"
kubectl exec --namespace pulsar -t pulsar-toolset-0 -- bin/pulsar-admin topics set-retention -s -1 -t -1 $TOPIC
echo "Getting retention"
kubectl exec --namespace pulsar -t pulsar-toolset-0 -- bin/pulsar-admin topics get-retention $TOPIC
echo "Producing 30000 msgs"
kubectl exec --namespace pulsar -t pulsar-toolset-0 -- bin/pulsar-perf produce -bm 1 -r 300 -m 30000 -s 102400 $TOPIC

echo "\n\nSTEP_2::TESTING DURABILITY\n\n" && sleep 3
echo "Consuming 30000 msgs"
kubectl exec --namespace pulsar -t pulsar-toolset-0 -- bin/pulsar-perf consume -ioThreads 4 -c 4 -sp Earliest $TOPIC &
CONSUMER_PID=$!

sleep 15
kubectl delete pod pulsar-broker-0 -n pulsar
kubectl delete pod pulsar-broker-1 -n pulsar
kubectl delete pod pulsar-broker-2 -n pulsar

# Let the brokers to start and consumer to finish the work
sleep 90
kill -15 $CONSUMER_PID && unset CONSUMER_PID && sleep 1

echo "\n\nSTEP_3::VERIFICATION\n\n" && sleep 3
echo "Verifing messages on the topic"
kubectl exec --namespace pulsar -t pulsar-toolset-0 -- bin/pulsar-perf read $TOPIC

# Wait for CTRL+C
sleep 1000000



