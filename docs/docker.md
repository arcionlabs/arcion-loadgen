container show / is full

docker system prune -a -f


https://github.com/moby/moby/issues/33775

docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          39        25        49.7GB    8.9GB (17%)
Containers      28        28        23.49GB   0B (0%)
Local Volumes   141       35        927.8GB   915.2GB (98%)
Build Cache     77        0         0B        0B