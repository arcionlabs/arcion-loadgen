#!/usr/bin/env python3

from urllib.parse import urlparse
import hydra
from omegaconf import DictConfig, OmegaConf

@hydra.main(version_base=None, config_path="yaml", config_name="config")
def my_app(cfg : DictConfig) -> None:
    print(OmegaConf.to_yaml(cfg))

if __name__ == "__main__":
    my_app()
