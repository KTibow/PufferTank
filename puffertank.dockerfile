FROM nvcr.io/nvidia/cuda:13.0.2-cudnn-devel-ubuntu24.04
ARG DEBIAN_FRONTEND=noninteractive

# Drop problematic libcuda.so
RUN rm -f /etc/ld.so.conf.d/00-compat-*.conf && ldconfig

# Core system packages + SSH/dev tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget sudo git build-essential clang cmake unzip \
    libx11-dev libglfw3 libgl1-mesa-dev python3.12-dev python3.12-venv \
    openssh-server ca-certificates locales \
    htop gdb tmux psmisc llvm ccache sqlite3 libomp-dev \
    && mkdir -p /run/sshd \
    && locale-gen en_US.UTF-8 || true \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Safer SSH defaults for a public cloud box.
# Root login by SSH key is allowed; password login is disabled.
RUN mkdir -p /etc/ssh/sshd_config.d \
    && printf '%s\n' \
        'PermitRootLogin prohibit-password' \
        'PasswordAuthentication no' \
        'PubkeyAuthentication yes' \
        'UsePAM no' \
        > /etc/ssh/sshd_config.d/puffertank.conf

# Install uv and clone PufferLib
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && . $HOME/.local/bin/env \
    && git clone --depth 1 --branch 4.0 https://github.com/KTibow/puffer /puffer

WORKDIR /puffer

# Sync Python deps
RUN --mount=type=cache,target=/root/.cache/uv \
    . $HOME/.local/bin/env && uv sync

# Run on container startup
COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]

# Bashrc
RUN echo "export PS1=$''" >> ~/.bashrc \
 && echo "alias diff='diff --color --palette=':ad=36:de=31:ln=33''" >> ~/.bashrc \
 && echo "cd /puffer" >> ~/.bashrc \
 && echo "export __GLX_VENDOR_LIBRARY_NAME=mesa" >> ~/.bashrc

EXPOSE 22

# Important: keep the container alive for SSH.
CMD ["sleep", "infinity"]
