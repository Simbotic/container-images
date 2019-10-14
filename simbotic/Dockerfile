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

######## STAGE: gst-dev-stage
FROM base as gst-dev-stage

RUN apt-get update && apt-get install -y --no-install-recommends \
        cmake \
        libgtk2.0-dev \
        libavcodec-dev \
        libavformat-dev \
        libswscale-dev \
        python-dev \
        python-numpy \
        libtbb2 \
        libtbb-dev \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        libdc1394-22-dev \
        libssl-dev \
        lldb \
        procps \
        lsb-release

# CUDA 10.0
RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-command-line-tools-10-0 \
        cuda-cublas-10-0 \
        cuda-cufft-10-0 \
        cuda-curand-10-0 \
        cuda-cusolver-10-0 \
        cuda-cusparse-10-0 \
        libcudnn7=7.4.1.5-1+cuda10.0

ENV LD_LIBRARY_PATH /usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH

RUN apt-get install -y --no-install-recommends \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-good1.0-dev \
    libgstreamer-plugins-bad1.0-dev \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    libgstrtspserver-1.0-dev \
    libgstreamer1.0-0 \
    gstreamer1.0-libav \
    gstreamer1.0-doc \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    gstreamer1.0-alsa \
    gstreamer1.0-gl \
    gstreamer1.0-gtk3 \
    gstreamer1.0-qt5 \
    gstreamer1.0-pulseaudio \
    gtk-doc-tools

# Tensorflow 1.13.1
RUN wget https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-gpu-linux-x86_64-1.13.1.tar.gz \
    && tar -C /usr/local -xzf libtensorflow-gpu-linux-x86_64-1.13.1.tar.gz \
    && ldconfig

# Remove old OpenCV
RUN apt remove --purge -y libopencv-dev

# Compile OpenCV 4.1.1
RUN git clone https://github.com/opencv/opencv.git
WORKDIR /opencv
RUN git checkout 4.1.1
RUN mkdir build
WORKDIR /opencv/build
RUN cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local -D BUILD_EXAMPLES=OFF -D OPENCV_GENERATE_PKGCONFIG=ON ..
RUN make
RUN make install
RUN ldconfig

ARG USERNAME=sim

USER $USERNAME
ENV HOME /home/$USERNAME
WORKDIR $HOME

# Latest Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y
ENV PATH=$HOME/.cargo/bin:$PATH
RUN rustup component add rls rust-analysis rust-src rustfmt clippy

######## STAGE: simbotic-engine-stage
FROM gst-dev-stage as simbotic-engine-stage

ARG USERNAME=sim
ENV HOME /home/$USERNAME

USER root

COPY ./simbotic_key $HOME
RUN eval $(ssh-agent) && \
    ssh-add $HOME/simbotic_key && \
    ssh-keyscan -H github.com >> /etc/ssh/ssh_known_hosts && \
    chmod 777 $HOME/simbotic_key

USER $USERNAME
WORKDIR $HOME

RUN eval $(ssh-agent) && \
    ssh-add $HOME/simbotic_key && \
    git clone git@github.com:Simbotic/SimboticEngine.git --depth 1 -b Simbotic/4.22

RUN mkdir -p $HOME/SimboticEngine/Engine/Plugins/Simbotic
WORKDIR $HOME/SimboticEngine/Engine/Plugins/Simbotic
RUN eval $(ssh-agent) && \
    ssh-add $HOME/simbotic_key && \
    git clone git@github.com:Simbotic/ue4-gst-plugin.git --depth 1 GStreamer
WORKDIR $HOME/SimboticEngine
RUN ./Setup.sh
RUN ./GenerateProjectFiles.sh
RUN make

USER $USERNAME

ENV SIMBOTIC_PROJECT $HOME/Project/
ENV SIMBOTIC_ROOT $HOME/SimboticEngine/

COPY --chown=$USERNAME:$USERNAME ./Drone_QRCode $SIMBOTIC_PROJECT
COPY --chown=$USERNAME:$USERNAME ./cook.sh $SIMBOTIC_PROJECT

######## STAGE: gst-plugin-stage
FROM simbotic-engine-stage as gst-plugin-stage

WORKDIR $HOME

RUN eval $(ssh-agent) && \
    ssh-add $HOME/simbotic_key && \
    git clone git@github.com:Simbotic/gst-tensorflow.git --depth 1 -b qrdetector Gst-elements

ENV SIMBOTIC_GST_ELEMENTS $HOME/Gst-elements/

WORKDIR $SIMBOTIC_GST_ELEMENTS
RUN cargo build

######## STAGE: cook-stage
FROM gst-plugin-stage as cook-stage

WORKDIR $SIMBOTIC_PROJECT
RUN ./cook.sh 1.0 Drone_QRCode

######## STAGE: production-stage
FROM base as production-stage

COPY --from=cook-stage SIMBOTIC_PROJECT/out/ ./out/