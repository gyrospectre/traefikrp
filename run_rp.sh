#!/bin/sh

DEF_IF=`route | grep '^default' | grep -o '[^ ]*$'`
LOCAL_IP=`ifconfig $DEF_IF | grep -o 'inet [^ ]*' | awk '{print $2}'`
sed -i "s/PROXY_HOST=.*/PROXY_HOST=$LOCAL_IP/g" docker-compose.yaml

# Create docker nets
echo "*** Creating Docker networks ***"
sudo docker network create web
echo " \e[32mdone\e[39m"

# Start Traefik
echo "*** Starting Traefik ***"
sudo docker-compose up -d traefik
echo " \e[32mdone\e[39m"

# Start Keyclock
echo "*** Starting Keycloak ***"
sudo ./clean-db.sh
sudo docker-compose up -d keycloak

echo -n "Waiting for server to become available "
until $(curl https://auth.localnet --insecure --silent | grep -q "Red Hat"); do
    printf '.'
    sleep 5
done
echo " \e[32mdone\e[39m"

# Create initial user
echo -n "Creating initial app user ..."
sudo docker exec -it traefikrp_keycloak_1 /opt/jboss/keycloak/bin/kcadm.sh create users -r rp -s username=testuser -s enabled=true --server http://127.0.0.1:8080/auth --realm master --user admin --password admin > /dev/null
sudo docker exec -it traefikrp_keycloak_1 /opt/jboss/keycloak/bin/kcadm.sh set-password -r rp --username testuser --new-password NEWPASSWORD --temporary --server http://127.0.0.1:8080/auth --realm master --user admin --password admin > /dev/null
echo " \e[32mdone\e[39m"

# Generate a new secret and update Keycloak client
echo -n "Generating new client secret ..."
SECRET=$(uuid)
sudo docker exec -it traefikrp_keycloak_1 /opt/jboss/keycloak/bin/kcadm.sh update clients/ff88533c-bb46-4f0d-a3ef-de47e1c4ad4d -r rp -s secret=$SECRET --server http://127.0.0.1:8080/auth --realm master --user admin --password admin > /dev/null
echo " \e[32mdone\e[39m"

# Update GK config and build
echo "*** Starting Gatekeeper ***"
sed 's/{{ SECRET }}/'"$SECRET"'/g' keycloak-gatekeeper.conf.template > keycloak/keycloak-gatekeeper.conf
sudo docker-compose up -d keycloak-gatekeeper
echo " \e[32mdone\e[39m"

echo
echo "*** Finished ***"
