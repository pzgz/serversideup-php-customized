# Learn more about the Server Side Up PHP Docker Images at:
# https://serversideup.net/open-source/docker-php/
FROM serversideup/php:8.4-fpm-nginx

# Switch to root before installing our PHP extensions
USER root
# RUN install-php-extensions bcmath gd

RUN apt-get update \
    && apt-get install -y --no-install-recommends dialog \
    && apt-get install -y --no-install-recommends openssh-server fail2ban \
    && echo "root:Docker!" | chpasswd \
    && ssh-keygen -A \
    && chmod 600 /etc/ssh/ssh_host_*_key \
    && chmod 644 /etc/ssh/ssh_host_*_key.pub \
    && chown root:root /etc/ssh/ssh_host_*_key

# Install git and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    curl \
    openssh-client \
    gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

    # PNPM support
# https://github.com/nodejs/corepack/issues/612
ENV COREPACK_INTEGRITY_KEYS='{"npm":[{"expires":"2025-01-29T00:00:00.000Z","keyid":"SHA256:jl3bwswu80PjjokCgh0o2w5c2U4LhQAE57gj9cz1kzA","keytype":"ecdsa-sha2-nistp256","scheme":"ecdsa-sha2-nistp256","key":"MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE1Olb3zMAFFxXKHiIkQO5cJ3Yhl5i6UPp+IhuteBJbuHcA5UogKo0EWtlWwW6KSaKoTNEYL7JlCQiVnkhBktUgg=="},{"expires":null,"keyid":"SHA256:DhQ8wR5APBvFHLF/+Tc+AYvPOdTpcIDqOhxsBHRwC7U","keytype":"ecdsa-sha2-nistp256","scheme":"ecdsa-sha2-nistp256","key":"MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEY6Ya7W++7aUPzvMTrezH6Ycx3c+HOKYCcNGybJZSCJq/fd7Qa8uuAKtdIkUQtQiEKERhAmE5lMMJhP8OkDOa2g=="}]}'    
SHELL ["/bin/bash", "-c"]
RUN npm install -g --force pnpm@latest-10 \
    && SHELL=bash pnpm setup \
    && source /root/.bashrc

# sshd server
COPY --chmod=644 ./configs/sshd_config /etc/ssh/
RUN mkdir -p /var/run/sshd
COPY ./s6-rc.d/sshd /etc/s6-overlay/s6-rc.d/sshd
COPY ./s6-rc.d/sshd-log /etc/s6-overlay/s6-rc.d/sshd-log
COPY ./s6-rc.d/sshd-log-prepare /etc/s6-overlay/s6-rc.d/sshd-log-prepare
RUN chmod +x /etc/s6-overlay/s6-rc.d/sshd/run
RUN chmod +x /etc/s6-overlay/s6-rc.d/sshd-log/run
RUN chmod +x /etc/s6-overlay/s6-rc.d/sshd-log-prepare/up
COPY ./s6-rc.d/user/contents.d/sshd-pipeline /etc/s6-overlay/s6-rc.d/user/contents.d/sshd-pipeline

# fail2ban
COPY ./s6-rc.d/fail2ban /etc/s6-overlay/s6-rc.d/fail2ban
RUN chmod +x /etc/s6-overlay/s6-rc.d/fail2ban/run
COPY ./configs/fail2ban-jail.d-sshd.conf /etc/fail2ban/jail.d/sshd.conf
COPY ./s6-rc.d/user/contents.d/fail2ban /etc/s6-overlay/s6-rc.d/user/contents.d/fail2ban

# set root password to empty
RUN passwd -d root

USER www-data
