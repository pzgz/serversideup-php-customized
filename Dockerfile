# Learn more about the Server Side Up PHP Docker Images at:
# https://serversideup.net/open-source/docker-php/
FROM serversideup/php:8.4-fpm-nginx

# Switch to root before installing our PHP extensions
USER root
# RUN install-php-extensions bcmath gd

RUN apt-get update \
    && apt-get install -y --no-install-recommends dialog \
    && apt-get install -y --no-install-recommends openssh-server \
    && echo "root:Docker!" | chpasswd \
    && ssh-keygen -A \
    && chmod 600 /etc/ssh/ssh_host_*_key \
    && chmod 644 /etc/ssh/ssh_host_*_key.pub \
    && chown root:root /etc/ssh/ssh_host_*_key

RUN mkdir -p /var/run/sshd

COPY --chmod=644 ./ssh/sshd_config /etc/ssh/

COPY ./ssh/ssh-server /etc/s6-overlay/s6-rc.d/ssh-server

USER www-data
