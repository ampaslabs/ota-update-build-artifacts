DOCKER_USER = "dockerhub-username"
DOCKER_REPO = "myapp"
VERSION = "1.0.0"

all: myapp docker-build push

myapp:
        gcc -o myapp myapp.c

docker-build:
        docker build -t $(DOCKER_USER)/$(DOCKER_REPO):$(VERSION) .

push: 
        docker login
        docker push $(DOCKER_USER)/$(DOCKER_REPO):$(VERSION)

clean:
        rm -f myapp

.PHONY: all myapp docker-build push clean