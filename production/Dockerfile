ARG UBUNTU_VERSION=18.04

######## STAGE: base
FROM nvidia/cudagl:10.0-devel-ubuntu${UBUNTU_VERSION} as base

ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES},display
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV TZ=America/Detroit

# setup timezone
RUN echo 'Etc/UTC' > /etc/timezone && \
    ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    apt-get update && apt-get install -q -y tzdata && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
        mesa-utils \
        build-essential \
        sudo \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libgl1 \
        libgl1-mesa-glx \
        libzmq3-dev \
        pkg-config \
        software-properties-common \
        ssh \
        curl \
        wget \
        git \
        git-lfs \
        vim \
        rsync \
        unzip \
        x11-xserver-utils \
        xdg-utils \
        xdg-user-dirs && \
        rm -rf /var/lib/apt/lists/*

RUN xdg-user-dirs-update

ARG USERNAME=sim
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Non-root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && usermod -a -G audio,video $USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
ENV HOME /home/$USERNAME
WORKDIR $HOME

COPY --from=simbotic:latest /home/sim/Project/out/ ./out/