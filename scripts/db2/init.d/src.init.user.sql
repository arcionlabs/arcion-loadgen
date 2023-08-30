CREATE TABLE IF NOT EXISTS REPLICATE_IO_CDC_HEARTBEAT(
  TIMESTAMP BIGINT NOT NULL,
  PRIMARY KEY(TIMESTAMP)
);

alter table  CUSTOMER                    data capture changes;
alter table  DISTRICT                    data capture changes;
alter table  HISTORY                     data capture changes;
alter table  ITEM                        data capture changes;
alter table  NEW_ORDER                   data capture changes;
alter table  OORDER                      data capture changes;
alter table  ORDER_LINE                  data capture changes;
alter table  REPLICATE_IO_CDC_HEARTBEAT  data capture changes;
alter table  STOCK                       data capture changes;
alter table  THEUSERTABLE                data capture changes;
alter table  WAREHOUSE                   data capture changes;
