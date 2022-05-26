# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

FROM gcr.io/oss-fuzz-base/base-builder
RUN apt-get update && apt-get install -y make autoconf automake libtool libdb-dev
RUN git clone --depth=1 https://github.com/vdukhovni/postfix postfix
RUN apt-get -y install afl++
RUN apt-get update && \
    apt-get -y install --no-install-suggests --no-install-recommends \
    automake \
    cmake \
    meson \
    ninja-build \
    bison flex \
    build-essential \
    git \
    python3 python3-dev python3-setuptools python-is-python3 \
    libtool libtool-bin \
    libglib2.0-dev \
    wget vim jupp nano bash-completion less \
    apt-utils apt-transport-https ca-certificates gnupg dialog \
    libpixman-1-dev \
    gnuplot-nox \
    && rm -rf /var/lib/apt/lists/*

# TODO: reactivate in timely manner
#RUN echo "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-15 main" >> /etc/apt/sources.list && \
#    wget -qO - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

RUN echo "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu jammy main" >> /etc/apt/sources.list && \
    apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 1E9377A2BA9EF27F
    
RUN apt-get full-upgrade -y && \
    apt-get -y install --no-install-suggests --no-install-recommends \
    gcc-12 g++-12 gcc-12-plugin-dev gdb lcov \
    clang-14 clang-tools-14 libc++1-14 libc++-14-dev \
    libc++abi1-14 libc++abi-14-dev libclang1-14 libclang-14-dev \
    libclang-common-14-dev libclang-cpp14 libclang-cpp14-dev liblld-14 \
    liblld-14-dev liblldb-14 liblldb-14-dev libllvm14 libomp-14-dev \
    libomp5-14 lld-14 lldb-14 llvm-14 llvm-14-dev llvm-14-runtime llvm-14-tools

# arm64 doesn't have gcc-multilib, and it's only used for -m32 support on x86
ARG TARGETPLATFORM
RUN [ "$TARGETPLATFORM" = "linux/amd64" ] && \
    apt-get -y install --no-install-suggests --no-install-recommends \
    gcc-10-multilib gcc-multilib || true

RUN rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 0
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 0

ENV LLVM_CONFIG=llvm-config-14
ENV AFL_SKIP_CPUFREQ=1
ENV AFL_TRY_AFFINITY=1
ENV AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1

RUN git clone --depth=1 https://github.com/vanhauser-thc/afl-cov /afl-cov
RUN cd /afl-cov && make install && cd ..

COPY AFLplusplus $SRC/


RUN export CC=gcc-12 && export CXX=g++-12 && make clean && \
    make distrib && make install && make clean

RUN sh -c 'echo set encoding=utf-8 > /root/.vimrc'
RUN echo '. /etc/bash_completion' >> ~/.bashrc
RUN echo 'alias joe="joe --wordwrap --joe_state -nobackup"' >> ~/.bashrc
RUN echo "export PS1='"'[afl++ \h] \w$(__git_ps1) \$ '"'" >> ~/.bashrc
ENV IS_DOCKER="1"

COPY . $SRC/postfix
WORKDIR postfix
COPY .clusterfuzzlite/build.sh $SRC/
COPY .clusterfuzzlite/*.c $SRC/
