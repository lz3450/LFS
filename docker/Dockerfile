FROM ubuntu:noble

# Install required packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential nano git zsh openssh-server sudo curl

# Create user kzl and set up password
RUN usermod -l kzl -p "$y$j9T$aQIZaUki99YOiZMqj/RJU0$fn3F/CP2kerZ8lq9SiWs6gssbUg9ZO8pJDvJg8BMuk." -s /bin/zsh -m -d /home/kzl -a -G sudo,adm ubuntu
RUN groupmod -n kzl ubuntu
RUN echo "kzl:password" | chpasswd

# Generate SSH host keys
RUN ssh-keygen -A

# Enable and start SSH service
RUN mkdir /run/sshd
RUN rmdir /bin.usr-is-merged
RUN rmdir /lib.usr-is-merged

# Switch to user kzl
USER kzl
WORKDIR /home/kzl

# Set up projects directory and clone repository
RUN git clone --depth 1 https://github.com/lz3450/LFS.git
RUN mkdir -p /home/kzl/Projects

# Set up zsh configuration
WORKDIR /home/kzl/LFS/config
RUN ./update-config.sh
WORKDIR /

# Expose SSH port
EXPOSE 22

# Set entrypoint to run sshd
CMD ["/usr/sbin/sshd", "-D"]

# docker build --no-cache -t ubuntu:noble .
# docker run -d --rm -u root -p 2222:22 --name noble -h NOBLE ubuntu:noble
# docker run -i -t --rm -u root -p 2223:22 --name noble -h NOBLE ubuntu:LFS /bin/bash
