#!/usr/bin/env python3

from confluent_kafka import Consumer
from omegaconf import OmegaConf

conf = OmegaConf.load('client.properties')
conf["group.id"] = "python-group-2"
conf["auto.offset.reset"] = "earliest"

consumer = Consumer(dict(conf))
consumer.subscribe(["arcdst_unicode"])
try:
    i = 0
    while True:
        msg = consumer.poll(1.0)
        if msg is not None and msg.error() is None:
            print("key = {key:12} value = {value:12}".format(key=msg.key().decode('utf-8'), value=msg.value().decode('utf-8')))
            i += 1
            if i > 10:
                break
except KeyboardInterrupt:
        pass
finally:
        consumer.close()