FROM strimzi/kafka:0.13.0-kafka-2.3.0
ENV KAFKA_VERSION=2.3.0
ENV KAFKA_CLI_DIR=/opt/kafka/bin
ENV PATH=/opt/kafka-toolbox:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
COPY bin /opt/kafka-toolbox
