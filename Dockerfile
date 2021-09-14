FROM alpine:latest

LABEL MAINTAINER="Stephen Checkley <scheckley@gmail.com>"

# Linking of locale.h as xlocale.h
# This is done to ensure successfull install of python numpy package
# see https://forum.alpinelinux.org/comment/690#comment-690 for more information.

WORKDIR /var/www/

# SOFTWARE PACKAGES
#   * musl: standard C library
#   * lib6-compat: compatibility libraries for glibc
#   * linux-headers: commonly needed, and an unusual package name from Alpine.
#   * build-base: used so we include the basic development packages (gcc)
#   * bash: so we can access /bin/bash
#   * git: to ease up clones of repos
#   * ca-certificates: for SSL verification during Pip and easy_install
#   * freetype: library used to render text onto bitmaps, and provides support font-related operations
#   * libgfortran: contains a Fortran shared library, needed to run Fortran
#   * libgcc: contains shared code that would be inefficient to duplicate every time as well as auxiliary helper routines and runtime support
#   * libstdc++: The GNU Standard C++ Library. This package contains an additional runtime library for C++ programs built with the GNU compiler
#   * openblas: open source implementation of the BLAS(Basic Linear Algebra Subprograms) API with many hand-crafted optimizations for specific processor types
#   * tcl: scripting language
#   * tk: GUI toolkit for the Tcl scripting language
#   * libssl1.0: SSL shared libraries
ENV PACKAGES="\
    dumb-init \
    musl \
    libc6-compat \
    linux-headers \
    build-base \
    bash \
    git \
    ca-certificates \
    freetype \
    libgfortran \
    libgcc \
    libstdc++ \
    openblas \
    tcl \
    tk \
    vim \
    R \
    R-dev \
"

RUN apk add --no-cache --virtual build-dependencies python3 --update py3-pip \
    && apk add --virtual build-runtime \
    build-base python3-dev openblas-dev freetype-dev pkgconfig gfortran jpeg-dev zlib-dev \
    && pip3 install numpy \
    && apk add --update --no-cache --virtual py3-pip py3-pandas py3-scipy py3-scikit-learn py3-cx_freeze py3-matplotlib \
    && ln -s /usr/include/locale.h /usr/include/xlocale.h \
    && apk del build-runtime \
    && apk add --no-cache --virtual build-dependencies $PACKAGES \
    && rm -rf /var/cache/apk/*

CMD ["bash"]
