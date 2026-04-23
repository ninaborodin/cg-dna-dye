FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# -------------------------------------------------
# System dependencies
# -------------------------------------------------
RUN apt-get update && apt-get install -y \
    build-essential git wget curl cmake \
    libopenmpi-dev openmpi-bin \
    gsl-bin libgsl-dev \
    liblapack-dev \
    python3-dev python3-pip \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------
# Install Miniforge (native ARM64)
# -------------------------------------------------
RUN wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh -O miniforge.sh \
    && bash miniforge.sh -b -p /opt/conda \
    && rm miniforge.sh
ENV PATH="/opt/conda/bin:$PATH"

# -------------------------------------------------
# Create environment
# -------------------------------------------------
RUN conda create -y -n mscg python=3.9 \
    numpy scipy cython matplotlib pyyaml pip

# -------------------------------------------------
# Install build dependencies via pip
# -------------------------------------------------
RUN conda run -n mscg pip install --upgrade pip setuptools wheel numpy cython

# -------------------------------------------------
# Install PyTorch (CPU)
# -------------------------------------------------
RUN conda run -n mscg pip install torch==2.2.0 torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cpu

# -------------------------------------------------
# Install PyTorch Geometric (from source for ARM64)
# -------------------------------------------------
RUN conda run -n mscg pip install torch-geometric \
    && conda run -n mscg pip install torch_scatter torch_sparse torch_cluster torch_spline_conv \
       --no-build-isolation

# -------------------------------------------------
# Clone OpenMSCG
# -------------------------------------------------
WORKDIR /
RUN git clone https://github.com/uchicago-voth/OpenMSCG.git

# -------------------------------------------------
# Install OpenMSCG and fix pkg_resources
# -------------------------------------------------
WORKDIR /OpenMSCG
RUN conda run -n mscg pip install --no-build-isolation -e . \
    && conda run -n mscg pip install setuptools

# -------------------------------------------------
# Default shell
# -------------------------------------------------
ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "mscg"]
CMD ["/bin/bash"]
