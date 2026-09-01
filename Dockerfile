# Apache APISIX gateway for Railway.
#
# `latest` floats deliberately: this image is rebuilt on every deploy, so each
# deployer gets the current stable APISIX rather than a tag frozen the day this
# repository was written.
FROM apache/apisix:latest

USER root

COPY apisix/config.yaml /usr/local/apisix/conf/config.yaml
COPY apisix/entrypoint.sh /usr/local/bin/railway-entrypoint.sh

RUN chown apisix:0 /usr/local/apisix/conf/config.yaml \
    && chmod g=u /usr/local/apisix/conf/config.yaml \
    && chmod 0755 /usr/local/bin/railway-entrypoint.sh \
    && bash -n /usr/local/bin/railway-entrypoint.sh

USER apisix

# The image's ENTRYPOINT is kept, so this reaches it as "$@" and is exec'd; it
# then hands back to `/docker-entrypoint.sh docker-start`. Declaring an
# ENTRYPOINT here instead would empty the inherited CMD.
CMD ["/usr/local/bin/railway-entrypoint.sh"]
