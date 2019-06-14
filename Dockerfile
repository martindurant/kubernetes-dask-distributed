FROM ubuntu:18.04
MAINTAINER Sarah Bird <sbird@mozilla.com>

RUN apt-get update -yqq && apt-get install -yqq bzip2 git wget && rm -rf /var/lib/apt/lists/*

# Configure environment
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN mkdir -p /work/bin

# Install Python 3 from miniconda
ADD https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh miniconda.sh
RUN bash miniconda.sh -b -p /work/miniconda && rm miniconda.sh

# keep conda in user dir, so can do conda install in notebook
ENV PATH="/work/bin:/work/miniconda/bin:$PATH"

# Install pydata stack
RUN conda config --set always_yes yes --set changeps1 no --set auto_update_conda no
RUN conda install -c conda-forge \
    bokeh \
    datashader \
    dask \
    distributed \
    dye-score \
    gcsfs \
    hdbscan \
    fastparquet \
    ipywidgets \
    lz4 \
    matplotlib \
    numpy \
    nodejs \
    notebook \
    nomkl \
    numba \
    numpy \
    pandas \
    pillow \
    pip \
    phantomjs \
    pyarrow \
    python-snappy \
    psutil \
    s3fs \
    scikit-learn \
    selenium \
    statsmodels \
    tldextract \
    tornado \
    tqdm \
    umap-learn \
    xarray \
    zarr \
 && conda clean -tipsy \
 && pip install openwpm-utils

RUN conda install -c conda-forge jupyterlab ipywidgets \
 && jupyter labextension install jupyterlab_bokeh \
 && jupyter labextension install jupyterlab_vim \
 && jupyter nbextension enable widgetsnbextension --py --sys-prefix \
 && conda clean -tipsy

# Install Tini that necessary to properly run the notebook service in docker
# http://jupyter-notebook.readthedocs.org/en/latest/public_server.html#docker-cmd
ENV TINI_VERSION v0.9.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini

# Add chromedriver for beautiful exports
RUN curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o /chrome.deb
RUN dpkg -i /chrome.deb || apt-get install -yf
RUN rm /chrome.deb
RUN curl https://chromedriver.storage.googleapis.com/75.0.3770.90/chromedriver_linux64.zip -o /usr/local/bin/chromedriver
RUN chmod +x /usr/local/bin/chromedriver

# For further interaction with kubernetes
ADD https://storage.googleapis.com/kubernetes-release/release/v1.5.4/bin/linux/amd64/kubectl /usr/sbin/kubectl
RUN chmod +x /usr/bin/tini && chmod 0500 /usr/sbin/kubectl

# Add local files at the end of the Dockerfile to limit cache busting
COPY config /work/config
COPY examples /work/examples
ENTRYPOINT ["/usr/bin/tini", "--"]

# Create a non-priviledge user that will run the client and workers
ENV BASICUSER basicuser
ENV BASICUSER_UID 1000
RUN useradd -m -d /work -s /bin/bash -N -u $BASICUSER_UID $BASICUSER \
 && chown $BASICUSER /work \
 && chown $BASICUSER:users -R /work
