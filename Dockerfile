FROM ubuntu:latest
LABEL \
	maintainer="mdPlusPlus" \
	description="Host your own ZeroTier network controller and manage it via ztncui."


# Avoid tzdata configuration
ARG DEBIAN_FRONTEND=noninteractive


# Dependencies
## TODO Figure out how to always get latest Node.js LTS release
RUN \
	apt update && \
	apt install -y --no-install-recommends curl g++ git gpg gpg-agent make && \
	curl -sL https://deb.nodesource.com/setup_12.x |  bash - && \
	apt install -y --no-install-recommends nodejs npm ca-certificates && \
	npm install -g npm && \
	npm install -g node-gyp && \
	curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg' | gpg --import ; \
	apt clean && \
	rm -rf /var/lib/apt/lists/*


# User (so zerotier-one is not using the reserved id 999)
RUN \
	groupadd -g 2000 zerotier-one && \
	useradd -u 2000 -g 2000 zerotier-one && \
	mkdir -p /home/zerotier-one && \
	chown -R zerotier-one:zerotier-one /home/zerotier-one


# ZeroTier-One
RUN \
	if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z" | bash; fi; exit 0


# ztncui
RUN \
	mkdir -p /opt/ztncui && chown zerotier-one:zerotier-one /opt/ztncui && \
	su zerotier-one -c "git clone https://github.com/key-networks/ztncui /opt/ztncui && \ 
		cd /opt/ztncui/src && \
			mv -v etc/default.passwd ../passwd.orig && \
			echo 'HTTPS_PORT=3443' >> .env" && \
	su zerotier-one -c "cd /opt/ztncui/src && npm install"


# Clean
## TODO


# Volumes
VOLUME ["/var/lib/zerotier-one/"]
VOLUME ["/opt/ztncui/src/etc/"]


# Ports
# HTTP:
EXPOSE 3000/tcp
# HTTPS:
EXPOSE 3443/tcp


# Start
CMD \
        chown -R zerotier-one:zerotier-one /var/lib/zerotier-one/ /opt/ztncui/src/etc/ && \
	su zerotier-one -c "zerotier-one -U -d" && \
        while [ ! -f /var/lib/zerotier-one/authtoken.secret ]; do sleep 1; done && \
        chmod g+r /var/lib/zerotier-one/authtoken.secret && \
	su zerotier-one -c "mkdir -p /opt/ztncui/src/etc/tls" && \
	if [ ! -f /opt/ztncui/src/etc/passwd ]; then su zerotier-one -c "mv -v /opt/ztncui/passwd.orig /opt/ztncui/src/etc/passwd"; fi && \
	if [ ! -f /opt/ztncui/src/etc/tls/privkey.pem ]; then su zerotier-one -c "openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:4096 -keyout /opt/ztncui/src/etc/tls/privkey.pem -out /opt/ztncui/src/etc/tls/fullchain.pem -subj '/C=XY/ST=XY/L=XY/O=XY/OU=XY/CN=XY'"; fi  && \
	su zerotier-one -c "cd /opt/ztncui/src && npm start"
