FROM ubuntu:bionic

LABEL MAINTAINER="Stephen Checkley <scheckley@gmail.com>"

# Do the root stuff.
USER root

# Update ubuntu and install some common tools.
RUN apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    zsh \
    bc \
    bzip2 \
    ca-certificates \
    cmake \
    gcc \
    git \
    gfortran \
    g++ \
    less \
    fonts-liberation \
    libgfortran3 \
    locales \
    make \
    nano \
    openssh-client \
    python3 \
    python3-pip \
    python3-setuptools \
    rsync \
    sudo \
    wget \
    curl \
    vim \
    zlib1g-dev \
    neofetch \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

 # Update pip to the latest version.
RUN python3 -m pip install --upgrade pip

RUN echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Install Tini - A tiny but valid init for containers https://github.com/krallin/tini.
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.10.0/tini && \
    echo "1361527f39190a7338a0b434bd8c88ff7233ce7b9a4876f3315c22fce7eca1b0 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Configure environment
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV SHELL /bin/bash
ENV NB_USER stephen
ENV NB_UID 1000
ENV LC_ALL en_GB.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB.UTF-8
# terminal colors with xterm
ENV TERM xterm

# Configure Miniconda
ENV MINICONDA_VER 4.6.14
ENV MINICONDA Miniconda3-$MINICONDA_VER-Linux-x86_64.sh
ENV MINICONDA_URL https://repo.continuum.io/miniconda/$MINICONDA
ENV MINICONDA_MD5_SUM 718259965f234088d785cad1fbd7de03

# Set up user environment variables.
ENV NB_USER=stephen \
    NB_UID=1000 \
    NB_GID=100 \
    LC_ALL=en_GB.UTF-8 \
    LANG=en_GB.UTF-8 \
    LANGUAGE=en_GB.UTF-8

# Create non-root user.
RUN useradd -m -s $SHELL -N -u $NB_UID $NB_USER

#pull down oh-my-zsh
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true

# pull down vundle vim plugin system
RUN git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

USER $NB_USER
# setup Vim
COPY .vimrc /home/stephen/.vimrc
# Install vim plugins
RUN [ "/bin/bash", "-c", "vim -T dumb -n -i NONE -es -S <(echo -e 'silent! PluginInstall')" ]

# set up zsh
COPY .zshrc /home/stephen/.zshrc

USER root
# Install conda as stephen
RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    curl -L $MINICONDA_URL  -o miniconda.sh && \
    echo "$MINICONDA_MD5_SUM  miniconda.sh" | md5sum -c - && \
    /bin/bash miniconda.sh -f -b -p $CONDA_DIR && \
    rm miniconda.sh && \
    $CONDA_DIR/bin/conda install --yes conda==$MINICONDA_VER

# pull down latest conda version
RUN conda update -n base -c defaults conda

# install data science packages
RUN conda install -c conda-forge pandas scikit-learn lightgbm xgboost keras statsmodels tqdm pymc3 numba networkx hyperopt pyarrow psutil flatbuffers setproctitle

RUN pip install ray

# Configure container startup as user
USER $NB_USER

CMD [ "zsh" ]