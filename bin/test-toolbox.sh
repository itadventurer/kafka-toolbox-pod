#!/bin/bash
red='\033[0;31m'
green='\033[0;32m'
normal='\e[0m'

function test_script {
    echo -e -n "Testing $@ …"
    $@ > /tmp/log 2>/tmp/err

    echo -e -n "\b"

    if [ -z "$(cat /tmp/err)" ]  || [ "$(cat /tmp/err)" != "Processed a total of 2 messages\n" ] ; then
        echo -e "${bold}${green}✓${normal}"
    else
        echo -e "${bold}${red}✗${normal}"
        cat /tmp/err
    fi
}

test_script kafka-acls --list
test_script kafka-broker-api-versions
test_script kafka-configs --entity-type topics --describe
test_script kafka-topics --create --topic kafka-toolbox-test --partitions 1 --replication-factor 1
echo -e "foo\nbar" | test_script kafka-console-producer --topic kafka-toolbox-test
test_script kafka-console-consumer --topic kafka-toolbox-test --offset 0 --partition 0 --max-messages 2
test_script kafka-consumer-groups --list
test_script kafka-consumer-perf-test --topic kafka-toolbox-test --messages 2
#test_script kafka-delegation-tokens
#test_script kafka-delete-records
test_script kafka-log-dirs --describe --broker-list 0
test_script kafka-preferred-replica-election
test_script kafka-producer-perf-test --topic kafka-toolbox-test --num-records 10 --record-size 10 --throughput 100
#test_script kafka-reassign-partitions
test_script kafka-streams-application-reset --application-id foo
test_script kafka-verifiable-producer --topic kafka-toolbox-test --max-messages 10
test_script kafka-verifiable-consumer --topic kafka-toolbox-test --max-messages 10 --group-id verifiable-consumer

test_script kafka-topics --delete --topic kafka-toolbox-test
#test_script zookeeper-shell
