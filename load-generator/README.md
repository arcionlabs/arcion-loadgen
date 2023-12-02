
# build image 

docker
```
cd arcion-loadgen
docker build -t robertslee/arcdemo:test -f load-generator/Dockerfile.arcdemo .
docker build -t robertslee/arcdemo -f load-generator/Dockerfile.arcdemo .
```

podman
````
cd arcion-loadgen
podman build -t robertslee/arcdemo:test -f load-generator/Dockerfile.arcdemo .
podman build -t robertslee/arcdemo -f load-generator/Dockerfile.arcdemo .
```

# Publish amd64, arm64  

```
docker buildx create --name mybuilder
docker buildx use mybuilder
docker buildx inspect --bootstrap
docker buildx build --push --platform=linux/amd64,linux/arm64/v8 -t robertslee/arcdemo -f load-generator/Dockerfile.arcdemo .

docker buildx build --push --platform=linux/amd64,linux/arm64/v8 -t robertslee/arcdemo:23.09 -f load-generator/Dockerfile.arcdemo .
```

# To start a container 

```
docker run -it --rm -p 7681:7681 robertslee/arcdemo
```

# To push to docker hub

```
docker tag 597de83199f4 robertslee/arcdemo
docker push robertslee/arcdemo
```

# For ghcr (Github container registery)
```
docker images | grep arcdemo
docker tag a1985aa6af86 ghcr.io/arcionlabs/arcdemo
docker push ghcr.io/arcionlabs/arcdemo:latest
```
