FROM scratch

# Install required packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential nano git zsh openssh-server sudo curl tmux

# Create user kzl and set up password
RUN useradd -m -U -G sudo,adm -s /bin/zsh kzl
RUN echo "kzl:password" | chpasswd

# Expose SSH port
EXPOSE 22

# Set default cmd to run sshd
CMD ["/usr/sbin/sshd", "-D"]

# Build the image
# docker build --no-cache -t <REPOSITORY:TAG> .

# Run the container in interactive mode
# docker run -i -t --rm -u root -p 2222:22 --name kzl-linux -h NOBLE <REPOSITORY:TAG> /bin/bash

# Run the container in detached mode
# docker run -d --rm -u root -p 2222:22 --name kzl-linux -h NOBLE <REPOSITORY:TAG>
# docker run -d --rm -u root -p 2222:22 --name kzl-linux -h NOBLE --mount type=bind,source=/home/kzl/LFS,target=/home/kzl/LFS --mount type=bind,source=/home/kzl/makepkg/sources,target=/home/kzl/makepkg/sources <REPOSITORY:TAG>
# docker run -d --rm -u root -p 2222:22 --name kzl-linux -h NOBLE --mount type=bind,source=/home/kzl/LFS,target=/home/kzl/LFS --mount type=bind,source=/home/kzl/Projects,target=/home/kzl/Projects --mount type=bind,source=/home/kzl/makepkg/sources,target=/home/kzl/makepkg/sources <REPOSITORY:TAG>
# docker run -d --rm -u root -p 2222:22 --name kzl-linux -h NOBLE --mount type=bind,source=/home/kzl/LFS,target=/home/kzl/LFS --mount type=bind,source=/home/kzl/Projects,target=/home/kzl/Projects --mount type=bind,source=/home/kzl/makepkg/sources,target=/home/kzl/makepkg/sources --mount type=bind,source=/home/kzl/wheels-noble,target=/home/kzl/wheels <REPOSITORY:TAG>
