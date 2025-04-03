FROM piptools:latest

ADD requirements.txt ./
RUN pip install -r requirements.txt

# Add jupyterlab extensions
RUN pip install jupyterlab_execute_time

# Git is needed for MLFlow tracking
RUN apt-get update -y && apt-get install -y git pkg-config cmake
RUN apt-get install -y gcc g++ gfortran libglpk-dev glpk-utils libblas-dev liblapack-dev
RUN apt-get install -y coinor-libipopt-dev

ENV PYTHONPATH="/home"
