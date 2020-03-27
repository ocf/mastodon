DOCKER_REVISION ?= testing-$(USER)
DOCKER_TAG = docker-push.ocf.berkeley.edu/mastodon:$(DOCKER_REVISION)

.PHONY: cook-image
cook-image:
	git clone https://github.com/tootsuite/mastodon -b v3.1.2 --depth 1 src
	cd src && git apply ../patches/* && \
	docker build --build-arg 'UID=1055' --build-arg 'GID=1055' --pull -t $(DOCKER_TAG) .
	rm -rf src

.PHONY: push-image
push-image: cook-image
	docker push $(DOCKER_TAG)

.PHONY: start-dev
start-dev: cook-image
	docker run --rm -ti $(DOCKER_TAG)
