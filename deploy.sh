helm repo add apache https://pulsar.apache.org/charts
helm repo update
helm upgrade --install pulsar -n pulsar -f ./values.yaml apache/pulsar --create-namespace