From alpine:latest

LABEL MAINTAINER="Stephen Checkley <scheckley@gmail.com>"

# Install glibc and useful packages
RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk --update add \
    bash \
    git \
    curl \
    wget \
    ca-certificates \
    bzip2 \
    unzip \
    sudo \
    glib \
    tini@testing \
    libssl1.1 \
    vim \
    zsh \
    && curl "https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub" -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -L "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-2.29-r0.apk" -o glibc.apk \
    && apk add glibc.apk \
    && curl -L "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-bin-2.23-r3.apk" -o glibc-bin.apk \
    && apk add glibc-bin.apk \
    && /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc/usr/lib \
    && rm -rf glibc*apk /var/cache/apk/*

#RUN apk add --no-cache --virtual build-dependencies python --update py-pip \
#    && apk add --virtual build-runtime \
#    build-base python-dev openblas-dev freetype-dev pkgconfig gfortran \
#    && ln -s /usr/include/locale.h /usr/include/xlocale.h \
#    && pip install --upgrade pip \
#    && apk del build-runtime \
#    && apk add --no-cache --virtual build-dependencies $PACKAGES \
#    && rm -rf /var/cache/apk/*

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

# Create non-root user with UID=1000 and in the 'users' group
RUN adduser -s /bin/bash -u $NB_UID -D $NB_USER && \
    mkdir -p /opt/conda && \
    chown stephen /opt/conda

USER stephen

#pull down oh-my-zsh
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true

# pull down vundle vim plugin system
RUN git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

# setup Vim
COPY .vimrc /home/stephen/.vimrc
# Install vim plugins
RUN [ "/bin/bash", "-c", "vim -T dumb -n -i NONE -es -S <(echo -e 'silent! PluginInstall')" ]

# set up zsh
COPY .zshrc /home/stephen/.zshrc

# Setup stephen home directory
RUN mkdir /home/$NB_USER/.jupyter && \
    mkdir /home/$NB_USER/.local

# Install conda as stephen
RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    curl -L $MINICONDA_URL  -o miniconda.sh && \
    echo "$MINICONDA_MD5_SUM  miniconda.sh" | md5sum -c - && \
    /bin/bash miniconda.sh -f -b -p $CONDA_DIR && \
    rm miniconda.sh && \
    $CONDA_DIR/bin/conda install --yes conda==$MINICONDA_VER

USER root

# pull down latest conda version
RUN conda update -n base -c defaults conda

# install data science packages
RUN conda install -c conda-forge pandas scikit-learn lightgbm xgboost keras statsmodels tqdm pymc3
numba networkx hyperopt pyarrow

RUN pip install halo

# Configure container startup as root
WORKDIR /home/$NB_USER/
ENTRYPOINT ["/sbin/tini", "--"]

# Switch back to stephen to avoid accidental container runs as root
USER stephen

#CMD [ "/bin/bash" ]
# start zsh
CMD [ "zsh" ]
