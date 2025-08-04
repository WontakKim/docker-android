FROM node:22-alpine

LABEL description="Android development environment for react native"

# Install system dependencies
RUN apk update && apk add --no-cache \
        bash \
        sudo \
        curl \
        wget \
        unzip \
        python3 \
        build-base \
        openjdk17-jdk \
        ruby-full \
        ruby-dev \
    && \
    rm -rf /tmp/* && \
    ruby -v && \
    gem install bundler && \
    bundle version

# Java
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# Gradle
ENV GRADLE_VERSION=8.10
ENV PATH=$PATH:/usr/local/gradle-${GRADLE_VERSION}/bin
RUN URL=https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
	curl -sSL -o /tmp/gradle.zip $URL && \
	unzip -d /usr/local /tmp/gradle.zip && \
	rm -rf /tmp/gradle.zip

# Android SDK Tools
ENV ANDROID_HOME=/opt/android
ENV ANDROID_SDK_ROOT=$ANDROID_HOME
ENV CMDLINE_TOOLS_ROOT=${ANDROID_HOME}/cmdline-tools/latest/bin

ENV ANDROID_BUILD_VERSION=34
ENV ANDROID_BUILD_TOOLS_VERSION=34.0.0

ENV ADB_INSTALL_TIMEOUT=10

ENV PATH=${ANDROID_HOME}/emulator:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/platform-tools/bin:${PATH}

# You can find the latest command line tools here: https://developer.android.com/studio#command-line-tools-only
RUN SDK_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" && \
	mkdir -p ${ANDROID_HOME}/cmdline-tools && \
	mkdir ${ANDROID_HOME}/platforms && \
	mkdir ${ANDROID_HOME}/ndk && \
	wget -O /tmp/cmdline-tools.zip -t 5 "${SDK_TOOLS_URL}" && \
	unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
	rm /tmp/cmdline-tools.zip && \
	mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest

RUN echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "platform-tools" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "platforms;android-${ANDROID_BUILD_VERSION}"

# Install some useful packages
RUN echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "extras;android;m2repository" && \
	echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "extras;google;m2repository" && \
	echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "extras;google;google_play_services"

# NDK
ENV NDK_VERSION=26.1.10909125
ENV CMAKE_VERSION=3.22.1

ENV ANDROID_NDK_HOME=${ANDROID_HOME}/ndk/${NDK_VERSION}
ENV CMAKE_BIN_PATH=${ANDROID_HOME}/cmake/${CMAKE_VERSION}/bin

ENV PATH=${ANDROID_NDK_HOME}:${CMAKE_BIN_PATH}:${PATH}

RUN echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "cmake;${CMAKE_VERSION}" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "ndk;${NDK_VERSION}"

# Fastlane
# https://docs.fastlane.tools/getting-started/ios/setup/#set-up-environment-variables
ENV LC_ALL=en_US
ENV LANG=en_US.UTF-8
RUN gem install fastlane --version 2.228.0 --no-document

# Infisical
RUN curl -1sLf https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.alpine.sh | bash && \
    apk add --no-cache infisical