FROM nvidia/cuda:8.0-cudnn6-devel

USER root
# Set the locale
RUN apt-get clean && apt-get -y update && apt-get install -y locales && locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# base OS
ENV DEBIAN_FRONTEND noninteractive
ADD https://github.com/nimbix/image-common/archive/master.zip /tmp/nimbix.zip
WORKDIR /tmp
RUN apt-get update && apt-get -y install sudo zip unzip && unzip nimbix.zip && rm -f nimbix.zip
RUN /tmp/image-common-master/setup-nimbix.sh
RUN touch /etc/init.d/systemd-logind && apt-get -y install module-init-tools xz-utils vim openssh-server libpam-systemd libmlx4-1 libmlx5-1 iptables infiniband-diags build-essential curl libibverbs-dev libibverbs1 librdmacm1 librdmacm-dev rdmacm-utils libibmad-dev libibmad5 byacc flex git cmake screen grep && apt-get clean && locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

# Nimbix JARVICE emulation
EXPOSE 22
RUN mkdir -p /usr/lib/JARVICE && cp -a /tmp/image-common-master/tools /usr/lib/JARVICE
RUN cp -a /tmp/image-common-master/etc /etc/JARVICE && chmod 755 /etc/JARVICE && rm -rf /tmp/image-common-master
RUN mkdir -m 0755 /data && chown nimbix:nimbix /data
RUN sed -ie 's/start on.*/start on filesystem/' /etc/init/ssh.conf




# Python dependencies and DL bibs
RUN apt-get update && \
    apt-get install --no-install-recommends -y --force-yes \
        git \
        graphviz \
        python-dev \
        python-flask \
        python-flaskext.wtf \
        python-gevent \
        python-h5py \
        python3-h5py \
        python-numpy \
        python-pil \
        python-pip \
        python3-pip \
        python-protobuf \
        python-scipy \
        python3-scipy \
        libpng12-0 \
        libpng12-dev \
        libfreetype6 \
        libjpeg-dev \
        libjpeg8 \
        libfreetype6-dev \
        build-essential \
	cmake \
	git \
	gfortran \
	libatlas-base-dev \
	libboost-all-dev \
	libgflags-dev \
	libgoogle-glog-dev \
	libhdf5-serial-dev \
	libleveldb-dev \
	liblmdb-dev \
	libopencv-dev \
	libprotobuf-dev \
	libsnappy-dev \
	protobuf-compiler \
	python-all-dev \
	python-dev \
	python-h5py \
	python3-h5py \
	python-matplotlib \
	python-numpy \
	python-opencv \
	python-pil \
	python-pip \
	python3-pip \
	python-protobuf \
	python-scipy \
	python3-scipy \
	python-skimage \
	python-sklearn \
        && apt-get build-dep -y --force-yes python-matplotlib \
	&& apt-get clean

# Update pip
RUN sudo pip install pip --upgrade
RUN sudo pip3 install pip --upgrade


# update dateutil
RUN sudo pip install pip --upgrade && sudo pip install python-dateutil --upgrade
RUN sudo pip3 install pip --upgrade && sudo pip3 install python-dateutil --upgrade




# Install AETROS
VOLUME /tmp
WORKDIR /tmp
USER nimbix
RUN sudo pip3 install pip --upgrade && sudo pip3 install aetros --upgrade
RUN sudo pip install pip --upgrade && sudo pip install aetros --upgrade

# Install Tensorflow for python and update h5py and scipy

RUN sudo pip3 install pip --upgrade && sudo pip3 install tensorflow-gpu && sudo pip3 install scipy --upgrade && sudo pip3 install h5py --upgrade
RUN sudo pip install pip --upgrade && sudo pip install tensorflow-gpu && sudo pip install scipy --upgrade && sudo pip install h5py --upgrade

# Install Caffe
VOLUME /tmp
WORKDIR /tmp
USER nimbix
RUN sudo apt-get install -y devscripts \
    dh-make \
    build-essential && sudo apt-get clean && \
    git clone https://github.com/NVIDIA/nccl.git && \
    cd /tmp/nccl && \
    make -j4 && \
    make debian && \
    make deb && \
    sudo dpkg -i build/deb/*.deb && cd /tmp && rm -rf /tmp/nccl

# example location - can be customized
USER root
ENV CAFFE_ROOT=/usr/local/caffe-nv
RUN git clone -b caffe-0.15 https://github.com/NVIDIA/caffe.git $CAFFE_ROOT && \
    pip install -r $CAFFE_ROOT/python/requirements.txt
WORKDIR $CAFFE_ROOT
RUN mkdir build && cd ${CAFFE_ROOT}/build && cmake -DUSE_NCCL=ON -DUSE_CUDNN=ON .. && make -j4 && make install