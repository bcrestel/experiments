###################
# PARAMETERS TO MODIFY
IMAGE_NAME = experiments
IMAGE_TAG = 1.0
###################
# FIXED PARAMETERS
TEST_FOLDER = src/tests
FORMAT_FOLDER = src
DOCKER_RUN = docker run -it --entrypoint=bash -w /home -v $(PWD):/home/
DOCKER_IMAGE = $(IMAGE_NAME):$(IMAGE_TAG)
DOCKER_IMAGE_PIPTOOLS = piptools:latest # NOTE: this image should already exist
###################

#
# build image
#
.PHONY : build
build: .build

.build: Dockerfile requirements.txt
	$(info ***** Building Image *****)
	docker build --rm -t $(DOCKER_IMAGE) .
	@touch .build

requirements.txt: requirements.in
	$(info ***** Pinning requirements.txt *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE_PIPTOOLS) -c "pip-compile --output-file requirements.txt requirements.in"
	#$(DOCKER_RUN) $(DOCKER_IMAGE_PIPTOOLS) -c "pip-compile --resolver=backtracking --output-file requirements.txt requirements.in" # adding this here just in case: resolver=backtracking was necessary to build another image once
	@touch requirements.txt

.PHONY : upgrade
upgrade:
	$(info ***** Upgrading dependencies *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE_PIPTOOLS) -c "pip-compile --upgrade --output-file requirements.txt requirements.in"
	@touch requirements.txt

#
# Run commands
#
.PHONY : run
run: build
	$(info ***** Running *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE)  -c "cd src; python hello_world.py"

.PHONY : shell
shell: build
	$(info ***** Creating shell *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE)

.PHONY : ipython
ipython: build
	$(info ***** Starting ipython session *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE) -c "ipython"

.PHONY : notebook
notebook: build
	$(info ***** Starting a notebook *****)
	$(DOCKER_RUN) -p 8888:8888 $(DOCKER_IMAGE) -c "jupyter lab --ip=$(hostname -I) --no-browser --allow-root"

.PHONY : mlflow_server
mlflow_server: build
	$(info ***** Starting the mlflow server *****)
	$(DOCKER_RUN) -p 5000:5000 $(DOCKER_IMAGE) -c "mlflow server -h 0.0.0.0"

#
# Testing
#
.PHONY : tests
tests: build
	$(info ***** Running all unit tests *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE) -c "python -m pytest -v --rootdir=$(TEST_FOLDER)"

#
# Formatting
#
.PHONY : format
format: build
	$(info ***** Formatting: running isort *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE) -c "isort -rc $(FORMAT_FOLDER)"
	$(info ***** Formatting: running black *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE) -c "black $(FORMAT_FOLDER)"

#
# Cleaning
#
.PHONY : clean
clean:
	$(info ***** Cleaning files *****)
	rm -rf .build .build_piptools requirements.txt
