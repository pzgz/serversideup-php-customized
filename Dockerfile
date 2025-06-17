# Learn more about the Server Side Up PHP Docker Images at:
# https://serversideup.net/open-source/docker-php/
FROM serversideup/php:8.4-fpm-nginx

# Switch to root before installing our PHP extensions
USER root
# RUN install-php-extensions bcmath gd

RUN apt-get update \
    && apt-get install -y --no-install-recommends dialog \
    && apt-get install -y --no-install-recommends openssh-server rsyslog fail2ban \
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

RUN echo "[sshd]\n\
enabled = true\n\
port = ssh\n\
logpath = /var/log/auth.log\n\
backend = systemd\n\
maxretry = 5\n\
findtime = 600\n\
bantime = 3600" > /etc/fail2ban/jail.d/sshd.conf    

# sshd server
RUN mkdir -p /var/run/sshd
COPY --chmod=644 ./ssh/sshd_config /etc/ssh/
COPY ./ssh/ssh-server /etc/s6-overlay/s6-rc.d/ssh-server
COPY ./ssh/contents.d/ssh-server /etc/s6-overlay/s6-rc.d/user/contents.d/ssh-server
RUN chmod +x /etc/s6-overlay/s6-rc.d/ssh-server/run

# rsyslog
COPY ./rsyslog/rsyslog /etc/s6-overlay/s6-rc.d/rsyslog
COPY ./rsyslog/contents.d/rsyslog /etc/s6-overlay/s6-rc.d/user/contents.d/rsyslog
RUN mkdir -p /var/run/rsyslog
RUN chmod +x /etc/s6-overlay/s6-rc.d/rsyslog/run
RUN echo "module(load=\"imuxsock\" SysSock.Name=\"/var/run/rsyslog/dev-log\")\n\
*.* /var/log/syslog\n\
auth,authpriv.* /var/log/auth.log" > /etc/rsyslog.conf

# fail2ban
COPY ./fail2ban/fail2ban /etc/s6-overlay/s6-rc.d/fail2ban
COPY ./fail2ban/contents.d/fail2ban /etc/s6-overlay/s6-rc.d/user/contents.d/fail2ban
RUN chmod +x /etc/s6-overlay/s6-rc.d/fail2ban/run

# set root password to empty
RUN passwd -d root

USER www-data
