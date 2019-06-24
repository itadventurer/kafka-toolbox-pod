FROM strimzi/kafka:0.11.3-kafka-2.1.0
ENV KAFKA_VERSION=2.1.0
ENV KAFKA_CLI_DIR=/opt/kafka/bin
ENV PATH=/opt/kafka-toolbox:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
COPY bin /opt/kafka-toolbox
