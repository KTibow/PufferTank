FROM nvcr.io/nvidia/cuda:13.0.2-cudnn-devel-ubuntu24.04
ARG DEBIAN_FRONTEND=noninteractive

# Drop problematic libcuda.so
RUN rm -f /etc/ld.so.conf.d/00-compat-*.conf && ldconfig

# Core system packages
# Custom installs without the cudnn base also need libnccl2 libnccl-dev
RUN apt-get update && apt-get install -y curl wget sudo git build-essential clang cmake unzip

# Install uv and clone PufferLib
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && . $HOME/.local/bin/env \
    && git clone https://github.com/KTibow/puffer --branch 4.0 /puffer

WORKDIR /puffer

# Sync Python deps
RUN --mount=type=cache,target=/root/.ccache . $HOME/.local/bin/env && uv sync

RUN apt-get install -y\
    htop gdb tmux psmisc llvm ccache \
    sqlite3 \
    libomp-dev libglfw3 libgl1-mesa-dev python3.12-dev

# Nsight Systems for profiling
RUN apt-get install -y --no-install-recommends nsight-systems-2025.6.3

# Run on container startup
COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]

# Bashrc
RUN echo "export PS1=$''" >> ~/.bashrc \
 && echo "alias diff='diff --color --palette=':ad=36:de=31:ln=33''" >> ~/.bashrc \
 && echo "cd /puffer" >> ~/.bashrc \
 && echo "export __GLX_VENDOR_LIBRARY_NAME=mesa" >> ~/.bashrc

RUN apt-get clean
CMD ["/bin/bash"]
