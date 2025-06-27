# Server Side Up PHP Docker Image - Customized with SSH

## Overview about changes made from the original `serversideup-php` image

* Switched to use `root` as default user for container, it means when container startup, the services will be ran by `root` user. But `www-data` will still be used to serve PHP and nginx
* Enabled `sshd` on port `10022`, so that it can be served by CI/CD tool, such as `deployer`
* `sshd` will generate log in `/var/log/sshd/current`
* Installed `fail2ban`, and it will use the sshd log file for jail processing, invalid user login and wrong password login will be banned, forever
* Disabled password login for every user, only login with key is supported
* Removed password for root
* only users in group `wheel` can use `su` for switching to root user, and make sure `www-data` is not in `wheel` group

# Readme from original image

A customized Docker image based on [Server Side Up's PHP Docker Images](https://serversideup.net/open-source/docker-php/) that includes SSH server functionality for development and debugging purposes.

## Overview

This project extends the `serversideup/php:8.4-fpm-nginx` base image by adding an SSH server, making it easier to access and debug containerized PHP applications during development.

## Features

- **PHP 8.4** with FPM and Nginx
- **SSH Server** with root access enabled
- **S6 Overlay** service management for SSH
- **Secure SSH Configuration** with customizable settings
- **Development-friendly** with password authentication enabled

## What's Included

### Base Image Features
- PHP 8.4 with FPM
- Nginx web server
- Optimized for production and development use
- S6 overlay for service management

### SSH Server Addition
- OpenSSH server installed and configured
- Root login enabled with password authentication
- SSH host keys automatically generated
- SFTP subsystem support
- Customizable SSH configuration

## Quick Start

### Build the Image

```bash
docker build -t my-php-ssh .
```

### Run the Container

```bash
docker run -d \
  --name my-php-app \
  -p 80:80 \
  -p 22:22 \
  -v $(pwd)/your-app:/var/www/html \
  my-php-ssh
```

### Access via SSH

```bash
ssh root@localhost
# Password: Docker!
```

## Configuration

### SSH Configuration

The SSH server is configured with the following settings (see `ssh/sshd_config`):

- **Port**: 22
- **Root Login**: Enabled
- **Password Authentication**: Enabled
- **X11 Forwarding**: Enabled
- **SFTP**: Supported

### Default Credentials

- **Username**: `root`
- **Password**: `Docker!`

> **Warning**: These default credentials are intended for development only. Change them for production use.

## File Structure

```
.
├── Dockerfile              # Main Docker image definition
├── ssh/
│   ├── sshd_config        # SSH server configuration
│   └── ssh-server/        # S6 service configuration
│       ├── run            # Service run script
│       └── type           # Service type definition
├── LICENSE                # MIT License
└── README.md             # This file
```

## Customization

### Changing SSH Password

To change the default SSH password, modify the Dockerfile:

```dockerfile
RUN echo "root:YourNewPassword" | chpasswd
```

### Adding PHP Extensions

Uncomment and modify the PHP extensions line in the Dockerfile:

```dockerfile
RUN install-php-extensions bcmath gd intl pdo_mysql redis
```

### Custom SSH Configuration

Modify `ssh/sshd_config` to adjust SSH server settings according to your needs.

## Use Cases

- **Development Environment**: Easy access to containerized applications for debugging
- **CI/CD Pipeline**: SSH access for deployment scripts and maintenance
- **Remote Development**: Direct file editing and command execution in containers
- **Debugging**: Access container internals without docker exec

## Security Considerations

- **Development Only**: This image is designed for development environments
- **Change Default Password**: Always change the default SSH password
- **Network Security**: Restrict SSH access using Docker networking or firewalls
- **Key-based Authentication**: Consider using SSH keys instead of passwords for production

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Server Side Up](https://serversideup.net/) for the excellent PHP Docker images
- The PHP and Docker communities for their continuous contributions

## Support

If you encounter any issues or have questions:

1. Check the [Server Side Up PHP Docker documentation](https://serversideup.net/open-source/docker-php/)
2. Review the SSH configuration in `ssh/sshd_config`
3. Ensure proper port mapping in your Docker run command
4. Verify SSH service is running: `docker exec <container> ps aux | grep sshd`
