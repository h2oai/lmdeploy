ARG BASE_IMAGE_VERSION=wolfi-cu12

FROM nvidia/cuda:12.4.1-devel-ubuntu22.04 AS cu12
ENV CUDA_VERSION_SHORT=cu121
ENV PATH=/opt/py3/bin:$PATH

FROM nvidia/cuda:11.8.0-devel-ubuntu22.04 AS cu11
ENV CUDA_VERSION_SHORT=cu118
ENV PATH=/opt/py3/bin:$PATH

FROM gcr.io/vorvan/h2oai/h2ogpt-lmdeploy-wolfi-base:2 AS wolfi-cu12
ENV CUDA_VERSION_SHORT=cu121
ENV WOLFI_OS=1

FROM ${BASE_IMAGE_VERSION} AS final

ARG PYTHON_VERSION=3.10

ARG TORCH_VERSION=2.3.0
ARG TORCHVISION_VERSION=0.18.0

RUN if [ -z "${WOLFI_OS}" ]; then \
    rm /etc/apt/sources.list.d/cuda*.list && apt-get update -y && apt-get install -y software-properties-common wget vim &&\
    add-apt-repository ppa:deadsnakes/ppa -y && apt-get update -y && apt-get install -y --no-install-recommends \
    ninja-build rapidjson-dev libgoogle-glog-dev gdb python${PYTHON_VERSION} python${PYTHON_VERSION}-dev python${PYTHON_VERSION}-venv \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* && cd /opt && python3 -m venv py3; \
    fi

RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools==69.5.1 &&\
    python3 -m pip install --no-cache-dir torch==${TORCH_VERSION} torchvision==${TORCHVISION_VERSION} --index-url https://download.pytorch.org/whl/${CUDA_VERSION_SHORT} &&\
    python3 -m pip install --no-cache-dir cmake packaging wheel

# install openmpi
RUN wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.5.tar.gz &&\
    tar xf openmpi-4.1.5.tar.gz && cd openmpi-4.1.5 && ./configure --prefix=/usr/local/openmpi &&\
    make -j$(nproc) && make install && cd .. && rm -rf openmpi-4.1.5*

ENV PATH=$PATH:/usr/local/openmpi/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/openmpi/lib

ENV NCCL_LAUNCH_MODE=GROUP

# Should be in the lmdeploy root directory when building docker image
COPY . /opt/lmdeploy

WORKDIR /opt/lmdeploy

RUN cd /opt/lmdeploy &&\
    python3 -m pip install --no-cache-dir -r requirements.txt &&\
    mkdir -p build && cd build &&\
    sh ../generate.sh &&\
    ninja -j$(nproc) && ninja install &&\
    cd .. &&\
    python3 -m pip install -e . &&\
    rm -rf build

ENV LD_LIBRARY_PATH=/opt/lmdeploy/install/lib:$LD_LIBRARY_PATH
ENV PATH=/opt/lmdeploy/install/bin:$PATH

# explicitly set ptxas path for triton
ENV TRITON_PTXAS_PATH=/usr/local/cuda/bin/ptxas

# Customize

WORKDIR /app

RUN pip3 uninstall pkg_resources -y
RUN pip3 install --upgrade pip
RUN pip3 install --upgrade setuptools==66.1.1
RUN pip3 uninstall -y ninja && pip3 install ninja
RUN PIP_EXTRA_INDEX_URL=https://download.pytorch.org/whl/cu121 pip3 install timm xformers triton==2.1.0 transformers
RUN MAX_JOBS=4 PIP_EXTRA_INDEX_URL=https://download.pytorch.org/whl/cu121 FLASH_ATTENTION_FORCE_BUILD=TRUE pip3 install flash-attn==2.5.2 --no-build-isolation
RUN pip3 install git+https://github.com/haotian-liu/LLaVA.git --no-deps

COPY . .

CMD ["lmdeploy", "serve", "api_server", "OpenGVLab/InternVL-Chat-V1-5"]
