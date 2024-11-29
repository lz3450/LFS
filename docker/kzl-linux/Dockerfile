FROM scratch

# Add the root filesystem to the image
ADD kzllinux_rootfs.tar.gz /

# Create user kzl and set up password
RUN useradd -m -U -G wheel,adm -s /bin/zsh kzl
RUN echo "kzl:password" | chpasswd

# Generate SSH host keys
RUN ssh-keygen -A

# Expose SSH port
EXPOSE 22

# Set default cmd to run sshd
CMD ["/usr/sbin/sshd", "-D"]

# Build the image
# docker build --no-cache -t kzl-linux:init .

# Run the container in interactive mode
# docker run -i -t --rm -u root -p 80:22 --name kzl-linux -h KZL-Linux kzl-linux:init /usr/bin/zsh


# Run the container in detached mode
# docker run -d --rm -u root -p 80:22 --name kzl-linux -h KZL-Linux kzl-linux:init
# docker run -d --rm -u root -p 2222:22 --name kzl-linux -h KZL-Linux --mount type=bind,source=/home/kzl/LFS,target=/home/kzl/LFS --mount type=bind,source=/home/kzl/makepkg/sources,target=/home/kzl/makepkg/sources <REPOSITORY:TAG>
# docker run -d --rm -u root -p 2222:22 --name kzl-linux -h KZL-Linux --mount type=bind,source=/home/kzl/LFS,target=/home/kzl/LFS --mount type=bind,source=/home/kzl/Projects,target=/home/kzl/Projects --mount type=bind,source=/home/kzl/makepkg/sources,target=/home/kzl/makepkg/sources <REPOSITORY:TAG>
# docker run -d --rm -u root -p 2222:22 --name kzl-linux -h KZL-Linux --mount type=bind,source=/home/kzl/LFS,target=/home/kzl/LFS --mount type=bind,source=/home/kzl/Projects,target=/home/kzl/Projects --mount type=bind,source=/home/kzl/makepkg/sources,target=/home/kzl/makepkg/sources --mount type=bind,source=/home/kzl/wheels-noble,target=/home/kzl/wheels <REPOSITORY:TAG>
