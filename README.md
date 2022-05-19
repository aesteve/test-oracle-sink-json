# Prerequisites

* docker installed, and running
* `curl`
* (`jq` would be nice, too)
* build the Kafka connect image of connect, containing the JDBC sink connector
```
docker build -f ConnectWithConnectors.Dockerfile -t connect-with-oracle-source:7.1.0 .
```

# Run

```
docker compose up -d
```

# Create RAW topic
```
docker exec -it broker bash
```
From inside the container:
```
kafka-console-producer --bootstrap-server localhost:9092 --topic raw_json --property parse.key=true --property key.separator=:
```
Then
```
1:{"orderid":"1","itemid":"something"}
```
<CTRL+D> to exit
```
exit
```
to exit the container


# KsqlDB to format the topic appropriately

* Point your browser at: http://localhost:9021/clusters 
* Go inside the running cluster then click the ksqlDB item menu.
* Drill down to the ksqldb1 cluster.
* Set `auto.offset.reset=earliest` in the drop-down field (under the query's textarea)
* Run the following query to create a stream from the "raw JSON" topic
```
CREATE STREAM RAW_STREAM(orderid STRING, itemid STRING) 
    WITH (KAFKA_TOPIC = 'raw_json', VALUE_FORMAT = 'JSON');
```
* Then, we can create a new stream with JSON_SR (or Avro, as you prefer) format with the same data as this "raw" topic
```
CREATE STREAM ORDERS 
	WITH (KAFKA_TOPIC = 'orders', VALUE_FORMAT = 'JSON_SR', PARTITIONS = 1) 
	AS SELECT * FROM RAW_STREAM;
```
We'll then be able to sink this newly created `formatted_json` topic (backing the STREAM) into Oracle, using JDBC Sink connector


# JDBC Sink connector

Create a JDBC sink connector
```
curl -X PUT \
     -H "Content-Type: application/json" \
     --data '{
               "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
                    "tasks.max": "1",
                    "connection.user": "myuser",
                    "connection.password": "mypassword",
                    "connection.url": "jdbc:oracle:thin:@oracle-db:1521/XE",
                    "topics": "orders",
                    "auto.create": "true",
                    "insert.mode":"insert",
                    "auto.evolve":"true",
                    "value.converter": "io.confluent.connect.json.JsonSchemaConverter",
                    "value.converter.schema.registry.url": "http://schema-registry:8081",
                    "pk.mode": "record_value",
                    "pk.fields": "ORDERID"
          }' \
     http://localhost:8083/connectors/oracle-sink/config | jq .
```

## Sending new data
```
docker exec -it broker bash
```
From inside the container:
```
kafka-console-producer --bootstrap-server localhost:9092 --topic raw_json --property parse.key=true --property key.separator=:
```
Then
```
2:{"orderid":"2","itemid":"something else"}
```
<CTRL+D> to exit
```
exit
```
to exit the container


# View data in Oracle

Open your favorite SQL viewer (Dbeaver, etc.) and connect to: `localhost:1521/xe` (using service name).
Login: `myuser`, Password: `mypassword`
The table `ORDERS` in the schema `MYUSER` should contain data.  
