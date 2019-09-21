# Kafka Toolbox Pod

This is a Docker image containing usefull tools preconfigured for easy
usage with Kafka.

## Included Tools


Currently following tools are implemented:

### Kafka CLI tools

* `kafka-acls`
* `kafka-broker-api-versions`
* `kafka-configs`
* `kafka-console-producer`
* `kafka-console-consumer`
* `kafka-consumer-groups`
* `kafka-consumer-perf-test`
* `kafka-delegation-tokens`
* `kafka-delete-records`
* `kafka-log-dirs`
* `kafka-preferred-replica-election`
* `kafka-producer-perf-test`
* `kafka-reassign-partitions`
* `kafka-streams-application-reset`
* `kafka-verifiable-producer`
* `kafka-verifiable-consumer`
* `kafka-topics`
* `zookeeper-shell`

If you have ideas for other useful tools please open an issue and
preferably submit a pull request.

## Features

* No need to remember if the tool requires `--bootstrap-server`,
  `--bootstrap-servers`, `--broker-list`, `--zookeeper`, `-b`
* Configuration via environment variables
* Support for PLAINTEXT and mutual TLS communication with brokers

## Usage

Start the docker image with the environment variables you need. In
general all environment variables are optional. But remember to set
them explicitly when you log into the container.

**Do not forget to first [Configure](#configuration) the environment variables**

### Run it on Kubernetes

1. Download your appropriate yaml file and configure as described below.
2. `kubectl apply -f my.yaml`
3. `kubectl run -it kafka-toolbox bash`
4. Do your work using the tools provided
5. Exit the pod
6. Delete the pod: `kubectl delete -f my.yaml`

### Use the tools

All tools are in the `PATH` so you can call them by name
(e.g. `kafka-console-consumer` or `kafkacat`)

See [./bin/test-toolbox.sh](./bin/test-toolbox.sh) for example usages

#### Kafka CLI Tools

```sh
kafka-acls --list
kafka-broker-api-versions
kafka-configs --entity-type topics --describe
kafka-topics --create --topic kafka-toolbox-test --partitions 1 --replication-factor 1
echo -e "foo\nbar" | kafka-console-producer --topic kafka-toolbox-test
kafka-console-consumer --topic kafka-toolbox-test --from-beginning --partition 0 --max-messages 2
kafka-consumer-groups --list
kafka-consumer-perf-test --topic kafka-toolbox-test --messages 2
kafka-delegation-tokens
kafka-delete-records
kafka-log-dirs --describe --broker-list 0
kafka-preferred-replica-election
kafka-producer-perf-test --topic kafka-toolbox-test --num-records 10 --record-size 10 --throughput 100
kafka-reassign-partitions
kafka-streams-application-reset --application-id foo
kafka-verifiable-producer --topic kafka-toolbox-test --max-messages 10
kafka-verifiable-consumer --topic kafka-toolbox-test --max-messages 10 --group-id verifiable-consumer --group-instance-id foo
kafka-topics --delete --topic kafka-toolbox-test
zookeeper-shell
```

## Configuration

### Kafka

Configure the `KAFKA_BOOTSTRAP_SERVERS` environment variable to point
to your bootstrap servers (usually one of the Kafka brokers – if you
are using Strimzi it is probably called `kafka-cluster-bootstrap`).

#### No authentication, no transport encryption

No additional configuration is required.

For Kubernetes deployments you can use following templates:


* [./assets/toolbox-plaintext.yaml](./assets/toolbox-plaintext.yaml):
  if connect to zookeeper without transport encryption
* [./assets/toolbox-plaintext-zookeeper-sidecar.yaml](./assets/toolbox-plaintext-zookeeper-sidecar.yaml):
  if you use a sidecar to encrypt zookeeper traffic

Do not forget to replace all values in `{{curly-brackets}}` by
appropriate values!

#### Mutual TLS

You need to provide following environment variables:

* `KAFKA_USER_KEY_LOCATION`
* `KAFKA_USER_CERT_LOCATION`
* `KAFKA_CA_CERT_LOCATION`

For Kubernetes deployments you can use following templates:


* [./assets/toolbox-mutual-tls.yaml](./assets/toolbox-mutual-tls.yaml)
  if connect to zookeeper without transport encryption
* [./assets/toolbox-mutual-tls-zookeeper-sidecar.yaml](./assets/toolbox-mutual-tls-zookeeper-sidecar.yaml):
  if you use a sidecar to encrypt zookeeper traffic

Do not forget to replace all values in `{{curly-brackets}}` by
appropriate values!

#### Other Authentication methods

currently not supported. If you need it, open a ticket or provide a
pull request. This should be quite straight forward.

### Zookeeper

### Plaintext Zookeeper traffic

Just provide the `KAFKA_ZOOKEEPER` environment variable.

### Encrypted Zookeeper traffic (the Strimzi way)

You need a TLS proxy sidecar that encrypts the Zookeeper traffic. Set
the `KAFKA_ZOOKEEPER` environment variable to `localhost:2181` (or the
port your sidecar requires)

## License

This project is licensed under the Apache License Version 2.0 (see
[LICENSE](./LICENSE)).
