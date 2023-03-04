
more info at https://github.com/informix/informix-dockerhub-readme/blob/master/14.10.FC1/informix-developer-database.md

```
docker run -d --name ifx -h ifx \
    -p 9088:9088 \
      -p 9089:9089 \
      -p 27017:27017 \
      -p 27018:27018 \
      -p 27883:27883 \
      -e LICENSE=accept \
      ibmcom/informix-developer-database:latest
```      