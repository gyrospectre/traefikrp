# traefikrp

Needs docker.io, docker-compose, curl, uuid

Add to /etc/hosts:
127.0.0.1	auth.localnet

To logout of the auth'd session:
https://auth.localnet/auth/realms/rp/protocol/openid-connect/logout?redirect_uri=https://hooroo.localnet/logout
