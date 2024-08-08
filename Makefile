
NPROCS                         := $(shell nproc)
VERSION                        := $(shell grep -oP "(?<=__version__ = ')[^']*" lmdeploy/version.py)-$(shell git rev-parse --short HEAD)
DOCKER_TEST_IMAGE_LMDEPLOY     := harbor.h2o.ai/h2ogpt/test-image-lmdeploy:$(VERSION)

ifeq ($(VERSION),)
  $(error Failed to extract version number from lmdeploy/version.py)
endif

LMDEPLOY_CUDA_VERSION ?= wolfi-cu12
LMDEPLOY_BASE_IMAGE   ?= gcr.io/vorvan/h2oai/h2ogpt-lmdeploy-wolfi-base:4

docker_build:
	docker pull $(LMDEPLOY_BASE_IMAGE)
	docker buildx build --load --build-arg BASE_IMAGE_VERSION=$(LMDEPLOY_CUDA_VERSION) --build-arg WOLFI_OS_BASE_IMAGE=$(LMDEPLOY_BASE_IMAGE) --tag $(DOCKER_TEST_IMAGE_LMDEPLOY) --file docker/Dockerfile .

docker_push:
	docker tag $(DOCKER_TEST_IMAGE_LMDEPLOY) gcr.io/vorvan/h2oai/h2ogpte-lmdeploy:$(VERSION)
	docker push gcr.io/vorvan/h2oai/h2ogpte-lmdeploy:$(VERSION)
