FROM ubuntu:noble

# Install required packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential nano git zsh openssh-server sudo curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create user kzl and set up password
RUN useradd -m -U -G sudo,adm kzl && \
    echo "kzl:password" | chpasswd

# Generate SSH host keys
RUN ssh-keygen -A

# Enable and start SSH service
RUN mkdir /run/sshd

# Switch to user kzl
USER kzl
WORKDIR /home/kzl

# Set up projects directory and clone repository
RUN git clone --depth 1 https://github.com/lz3450/LFS.git
RUN mkdir -p /home/kzl/Projects

# Set up zsh configuration
WORKDIR /home/kzl/LFS/config/zsh
RUN ./oh-my-zsh.sh

# Link configurations
RUN ln -rsf /home/kzl/LFS/config/git/.gitconfig /home/kzl/
RUN ln -rsf /home/kzl/LFS/config/nano/.nanorc /home/kzl/

# Expose SSH port
EXPOSE 22

# Set entrypoint to run sshd
ENTRYPOINT ["/usr/sbin/sshd", "-D"]

# docker build --no-cache -t ubuntu:noble .
# docker run -d --rm -u root -p 2222:22 --name noble -h NOBLE ubuntu:noble
