
```bash
cd /opt
wget https://github.com/rapiddweller/rapiddweller-benerator-ce/releases/download/3.1.0/rapiddweller-benerator-ce-3.1.0-jdk-11-dist.tar.gz
gzip -dc rapiddweller-benerator-ce-3.1.0-jdk-11-dist.tar.gz | tar -xvf -
export BENERATOR_HOME=`pwd`/rapiddweller-benerator-ce-3.1.0-jdk-11
chmod a+x $BENERATOR_HOME/bin/*
```