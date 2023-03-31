#!/usr/bin/env python3

from confluent_kafka import Producer
from omegaconf import OmegaConf

conf = OmegaConf.load('client.properties')
producer = Producer(dict(conf))
producer.produce("my-topic", key="key", value="value")
producer.flush()