FROM ubuntu:24.04

LABEL description="Android development environment for react native"

# Change default shell for RUN from Dash to Bash
SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=dumb \
    PAGER=cat

RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    git \
    locales \
    && \
    locale-gen en_US.UTF-8

# configure locale
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    openssh-client \
    gnupg \
    # for build
    ruby-full \
    python3 \
    python-is-python3 \
    openjdk-17-jdk-headless \
    build-essential \
    make \
    cmake \
    ccache \
    # for hermes engine
    libicu-dev \
    # utils
    wget \
    tar \
    zip \
    unzip \
    nano \
    && \
    gem install bundler && \
    # test
    ruby -v && \
    python --version && \
    bundle version

# configure node
ENV NODE_VERSION=22.18.0
RUN [[ $(uname -m) == "x86_64" ]] && ARCH="x64" || ARCH="arm64" && \
    curl -L -o /tmp/node.tar.xz "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz" && \
    tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 && \
    rm /tmp/node.tar.xz && \
    ln -s /usr/local/bin/node /usr/local/bin/nodejs
RUN npm install -g npm-cli-login

# configure android
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV ANDROID_BUILD_VERSION=34
ENV ANDROID_BUILD_TOOLS_VERSION=34.0.0
ENV NDK_VERSION=26.1.10909125
ENV CMAKE_VERSION=3.22.1

ENV ANDROID_HOME=/opt/android
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV ANDROID_NDK_HOME=${ANDROID_HOME}/ndk/${NDK_VERSION}
ENV CMDLINE_TOOLS_ROOT=${ANDROID_HOME}/cmdline-tools/latest/bin
ENV CMAKE_BIN_PATH=${ANDROID_HOME}/cmake/${CMAKE_VERSION}/bin

ENV ADB_INSTALL_TIMEOUT=10

# You can find the latest command line tools here: https://developer.android.com/studio#command-line-tools-only
RUN SDK_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip" && \
    mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    mkdir ${ANDROID_HOME}/platforms && \
    mkdir ${ANDROID_HOME}/ndk && \
    wget -O /tmp/cmdline-tools.zip -t 5 "${SDK_TOOLS_URL}" && \
    unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    rm /tmp/cmdline-tools.zip && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest

RUN echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "platform-tools" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "platforms;android-${ANDROID_BUILD_VERSION}" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "build-tools;35.0.0" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "build-tools;35.0.1" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "build-tools;36.0.0" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "platforms;android-35" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "platforms;android-36"

RUN echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "cmake;${CMAKE_VERSION}" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "ndk;${NDK_VERSION}"

# # install some useful packages
RUN echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "extras;android;m2repository" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "extras;google;m2repository" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "extras;google;google_play_services" && \
    gem install fastlane --version 2.228.0 --no-document

# infisical
RUN curl -1sLf 'https://artifacts-cli.infisical.com/setup.deb.sh' | sudo -E bash && \
    apt-get update && apt-get install -y infisical

# remove apt caches
RUN rm -rf /var/lib/apt/lists/*

# opt-out of the new security feature, not needed in a CI environment
RUN git config --global --add safe.directory '*'