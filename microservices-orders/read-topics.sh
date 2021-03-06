#!/bin/bash

################################

echo -e "\n*** Sampling messages in Kafka topics and a KSQL stream ***\n"

# Topic customers: populated by Kafka Connect that uses the JDBC source connector to read customer data from a sqlite3 database
echo -e "\n-----customers-----"
confluent local services kafka consume customers --value-format avro --property print.key=true --property key.deserializer=org.apache.kafka.common.serialization.LongDeserializer --from-beginning --max-messages 5 2> /dev/null

# Topic orders: populated by a POST to the OrdersService service. A unique order is requested 1 per second
echo -e "\n-----orders-----"
confluent local services kafka consume orders --value-format avro --property print.key=true --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --from-beginning --max-messages 5 2> /dev/null

# Topic payments: populated by PostOrdersAndPayments writing to the topic after placing an order. One payment is made per order
echo -e "\n-----payments-----"
confluent local services kafka consume payments --value-format avro --property print.key=true --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --from-beginning --max-messages 5 2> /dev/null

# Topic order-validations: PASS/FAIL for each "checkType": ORDER_DETAILS_CHECK (OrderDetailsService), FRAUD_CHECK (FraudService), INVENTORY_CHECK (InventoryService)
echo -e "\n-----order-validations-----"
confluent local services kafka consume order-validations --value-format avro --from-beginning --max-messages 15 2> /dev/null

# Topic warehouse-inventory: initial inventory in stock
echo -e "\n-----warehouse-inventory-----"
confluent local services kafka consume warehouse-inventory --property print.key=true --property value.deserializer=org.apache.kafka.common.serialization.IntegerDeserializer --from-beginning --max-messages 2 2> /dev/null

# Topic InventoryService-store-of-reserved-stock-changelog: table backing the reserved inventory
# It maxes out when orders = initial inventory
echo -e "\n-----InventoryService-store-of-reserved-stock-changelog-----"
confluent local services kafka consume InventoryService-store-of-reserved-stock-changelog --property print.key=true --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer -from-beginning --from-beginning --max-messages 5 2> /dev/null

# Topic platinum: dynamic routing
echo -e "\n-----platinum-----"
confluent local services kafka consume platinum --value-format avro --property print.key=true --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --from-beginning --max-messages 3 --timeout-ms 10000 2> /dev/null

# Read queries
ksql http://localhost:8088 <<EOF
SET CLI COLUMN-WIDTH 15
SELECT * FROM orders_cust1_joined EMIT CHANGES LIMIT 2;
SELECT * FROM FRAUD_ORDER EMIT CHANGES LIMIT 2;
exit ;
EOF
