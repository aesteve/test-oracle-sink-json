# https://docs.confluent.io/home/connect/self-managed/extending.html
FROM confluentinc/cp-kafka-connect-base:7.1.0

RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.4.1
