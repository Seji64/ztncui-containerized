# ztncui-containerized

# Why? There is already a offical Docker Image

Cause i am came across this issue https://github.com/key-networks/ztncui-containerized/issues/11 the only solution i found was using the Docker Image from https://gist.github.com/mdPlusPlus (all credits goes to him!)

But sadly could not get my treafik get to work with the https backend.I could not cause use HTTP cause it was not properly exposed in his Dockerfile.

Short version of the Story: I took his Dockerfile and "fixed" the expose of the HTTP Endpoint.

# Ok, cool - How to use?

```
zerotier:
    image: seji/ztncui-containerized
    container_name: zerotier
    ports:
      - 3000:3000
      - 3443:3443
    volumes:
      - /opt/zerotier/ztncui:/opt/ztncui/src/etc/
      - /opt/zerotier/zt1:/var/lib/zerotier-one/
    networks:
      - web
    labels:
      - traefik.enable=true
      - traefik.http.routers.zerotier.rule=Host(`zerotier.example.com`)
      - traefik.http.routers.zerotier.tls=true
      - traefik.http.routers.zerotier.entrypoints=web-secure
      - traefik.http.routers.zerotier.tls.certresolver=le
      - traefik.http.services.zerotier.loadbalancer.server.port=3000

```

