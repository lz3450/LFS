FROM ubuntu:noble

# Install required packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y locales whiptail build-essential nano git zsh openssh-server sudo curl tmux

# Create user kzl and set up password
RUN usermod -l kzl -a -G sudo,adm -m -d /home/kzl -s /bin/zsh ubuntu
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
RUN mkdir -p /home/kzl/LFS
RUN mkdir -p /home/kzl/Projects
RUN mkdir -p /home/kzl/makepkg/sources
RUN mkdir -p /home/kzl/wheels

# Set up projects directory and clone repository
# RUN git clone --depth 1 https://github.com/lz3450/LFS.git
# RUN mkdir -p /home/kzl/Projects

# Set up zsh configuration
# WORKDIR /home/kzl/LFS/config
# RUN ./update-config.sh
# WORKDIR /home/kzl

# Expose SSH port
EXPOSE 22

# Set default cmd to run sshd
CMD ["/usr/sbin/sshd", "-D"]

# Build the image
# docker build --no-cache -t <REPOSITORY:TAG> .

# Run the container in interactive mode
# docker run -i -t --rm -u root -p 2222:22 --name noble -h NOBLE <REPOSITORY:TAG> /bin/bash

# Run the container in detached mode
# docker run -d --rm -u root -p 2222:22 --name noble -h NOBLE <REPOSITORY:TAG>
# docker run -d --rm -u root -p 2222:22 --name noble -h NOBLE --mount type=bind,source=/home/kzl/LFS,target=/home/kzl/LFS --mount type=bind,source=/home/kzl/Projects,target=/home/kzl/Projects --mount type=bind,source=/home/kzl/makepkg/sources,target=/home/kzl/makepkg/sources <REPOSITORY:TAG>
# docker run -d --rm -u root -p 2222:22 --name noble -h NOBLE --mount type=bind,source=/home/kzl/LFS,target=/home/kzl/LFS --mount type=bind,source=/home/kzl/Projects,target=/home/kzl/Projects --mount type=bind,source=/home/kzl/makepkg/sources,target=/home/kzl/makepkg/sources --mount type=bind,source=/home/kzl/wheels-noble,target=/home/kzl/wheels <REPOSITORY:TAG>
