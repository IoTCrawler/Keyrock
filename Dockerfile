ARG NODE_VERSION=8.16.1-slim
FROM node:${NODE_VERSION}

WORKDIR /opt

# 
# ALL ENVIRONMENT VARIABLES
#
# ENV IDM_HOST "http://localhost"
# ENV IDM_PORT "3000"

# ENV IDM_DEBUG "true"

# ENV IDM_HTTPS_ENABLED true
# ENV IDM_HTTPS_PORT "443"

# ENV IDM_SESSION_SECRET "nodejs_idm"
# ENV IDM_SESSION_DURATION "3600000"

# ENV IDM_OAUTH_EMPTY_STATE false
# ENV IDM_OAUTH_AUTH_LIFETIME "300"
# ENV IDM_OAUTH_ACC_LIFETIME "3600"
# ENV IDM_OAUTH_ASK_AUTH true
# ENV IDM_OAUTH_REFR_LIFETIME "1209600"
# ENV IDM_OAUTH_UNIQUE_URL false

# ENV IDM_API_LIFETIME "3600"

# ENV IDM_ENCRYPTION_KEY "nodejs_idm"

# ENV IDM_CORS_ENABLED "false"),
# ENV IDM_CORS_ORIGIN "*"),
# ENV IDM_CORS_METHODS 'GET,HEAD,PUT,PATCH,POST,DELETE'),
# ENV IDM_CORS_ALLOWED_HEADERS undefined
# ENV IDM_CORS_EXPOSED_HEADERS undefined
# ENV IDM_CORS_CREDENTIALS undefined
# ENV IDM_CORS_MAS_AGE undefined
# ENV IDM_CORS_PREFLIGHT false
# ENV IDM_CORS_OPTIONS_STATUS 204

# ENV IDM_PDP_LEVEL "basic"
# ENV IDM_AUTHZFORCE_ENABLED false
# ENV IDM_AUTHZFORCE_HOST "localhost"
# ENV IDM_AUTHZFORCE_PORT" 8080"

# ENV IDM_USAGE_CONTROL_ENABLED false
# ENV IDM_PTP_HOST localhost
# ENV IDM_PTP_PORT 8081

# ENV IDM_DB_HOST "localhost"
# ENV IDM_DB_PASS "idm"
# ENV IDM_DB_USER "root"
# ENV IDM_DB_NAME "idm"
# ENV IDM_DB_DIALECT "mysql"
# ENV IDM_DB_PORT "3306"

# ENV IDM_EX_AUTH_ENABLED false
# ENV IDM_EX_AUTH_ID_PREFIX "external_"
# ENV IDM_EX_AUTH_PASSWORD_ENCRYPTION "sha1"
# ENV IDM_EX_AUTH_PASSWORD_ENCRYPTION_KEY undefined
# ENV IDM_EX_AUTH_DB_HOST "localhost"
# ENV IDM_EX_AUTH_PORT undefined
# ENV IDM_EX_AUTH_DB_NAME "db_name"
# ENV IDM_EX_AUTH_DB_USER "db_user"
# ENV IDM_EX_AUTH_DB_PASS "db_pass"
# ENV IDM_EX_AUTH_DB_USER_TABLE "user_view"
# ENV IDM_EX_AUTH_DIALECT "mysql"

# ENV IDM_EMAIL_HOST "localhost"
# ENV IDM_EMAIL_PORT "25"
# ENV IDM_EMAIL_ADDRESS "noreply@localhost"
# ENV IDM_EMAIL_LIST null

# ENV IDM_TITLE "Identity Manager"
# ENV IDM_THEME "default"

# ENV IDM_EIDAS_ENABLED false
# ENV IDM_EIDAS_GATEWAY_HOST "localhost"
# ENV IDM_EIDAS_NODE_HOST "https://se-eidas.redsara.es/EidasNode/ServiceProvider"
# ENV IDM_EIDAS_METADATA_LIFETIME "31536000"

# ENV IDM_ADMIN_ID    "admin"
# ENV IDM_ADMIN_USER  "admin"
# ENV IDM_ADMIN_EMAIL "admin@test.com"
# ENV IDM_ADMIN_PASS  "1234"



ENV IDM_HOST="http://localhost:3000" \
    IDM_PORT="3000" \
    IDM_PDP_LEVEL="basic" \
    IDM_DB_HOST="localhost" \
    IDM_DB_NAME="idm" \
    IDM_DB_DIALECT="mysql" \
    IDM_EMAIL_HOST="localhost" \
    IDM_EMAIL_PORT="25" \
    IDM_EMAIL_ADDRESS="noreply@localhost"

# IMPORTANT: For a Production Environment Use Docker Secrets to define
#  these values and add _FILE to the name of the variable.

# Install Ubuntu dependencies & email dependency & Configure mail
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential python debconf-utils curl git netcat  && \
    echo "postfix postfix/mailname string ${IDM_EMAIL_ADDRESS}" | debconf-set-selections && \
    echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections && \
    apt-get install -y --no-install-recommends postfix mailutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    sed -i 's/inet_interfaces = all/inet_interfaces = loopback-only/g' /etc/postfix/main.cf


COPY . /opt/fiware-idm

WORKDIR /opt/fiware-idm

RUN npm cache clean -f   && \
    npm install --production  && \
    rm -rf /root/.npm/cache/* && \
    mkdir certs && \
    openssl genrsa -out idm-2018-key.pem 2048 && \
    openssl req -new -sha256 -key idm-2018-key.pem -out idm-2018-csr.pem -batch && \
    openssl x509 -req -in idm-2018-csr.pem -signkey idm-2018-key.pem -out idm-2018-cert.pem 
    # && \ mv idm-2018-key.pem idm-2018-cert.pem idm-2018-csr.pem certs/

COPY servidor.iotcrawler.org_cert.pem certs/idm-2018-cert.pem
COPY servidor.iotcrawler.org_privkey.pem certs/idm-2018-key.pem

# Run Idm Keyrock
RUN cp extras/docker/docker-entrypoint.sh ./ && \
    cp extras/docker/config.js.template ./config.js && \
    chmod 755 docker-entrypoint.sh

ENTRYPOINT ["/opt/fiware-idm/docker-entrypoint.sh"]

# Ports used by idm
EXPOSE ${IDM_PORT}
