FROM ubuntu:jammy

# Install required packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y locales whiptail build-essential nano git zsh openssh-server sudo curl tmux

# Create user kzl and set up password
RUN useradd -m -U -G sudo,adm -s /bin/zsh kzl
RUN echo "kzl:password" | chpasswd

# Generate SSH host keys
RUN ssh-keygen -A

# Enable and start SSH service
RUN mkdir /run/sshd

# Switch to user kzl
USER kzl
WORKDIR /home/kzl
RUN mkdir -p /home/kzl/LFS
RUN mkdir -p /home/kzl/Projects
RUN mkdir -p /home/kzl/makepkg/sources
RUN mkdir -p /home/kzl/wheels

# Expose SSH port
EXPOSE 22

# Set default cmd to run sshd
CMD ["/usr/sbin/sshd", "-D"]

# Build the image
# docker build --no-cache -t <REPOSITORY:TAG> .

# Run the container in interactive mode
# docker run -i -t --rm -u root -p 2223:22 --name jammy -h JAMMY <REPOSITORY:TAG> /bin/bash

# Run the container in detached mode
# docker run -d --rm -u root -p 2223:22 --name jammy -h JAMMY <REPOSITORY:TAG>
# docker run -d --rm -u root -p 2223:22 --name jammy -h JAMMY --mount type=bind,source=/home/kzl/LFS,target=/home/kzl/LFS --mount type=bind,source=/home/kzl/Projects,target=/home/kzl/Projects --mount type=bind,source=/home/kzl/makepkg/sources,target=/home/kzl/makepkg/sources <REPOSITORY:TAG>
