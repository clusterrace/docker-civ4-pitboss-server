# UID/GID with right to write into PATH_TO_PBs
DOCKER_USER?=civpb
UID_IN_DOCKER=$(shell id -u "$(DOCKER_USER)")
GID_IN_DOCKER=$(shell id -g "$(DOCKER_USER)")
# UID_IN_DOCKER?=$(shell stat -c "%u" "$PATH_TO_PBs")
# GID_IN_DOCKER?=$(shell stat -c "%g" "$PATH_TO_PBs")

GAMEID?=PB1
IMAGE:=pbserver


# Shortcut to find ID of container
CONTAINER:=$$(docker ps -q -n 1 --filter 'name=Civ4_$(GAMEID)')

help:
	echo "Run 'make build' to create docker image '$(IMAGE)'"
	echo "All other task can be done by 'pitbossctl'"

build:
	docker build -t "$(IMAGE)" \
		--build-arg UNAME="$(DOCKER_USER)" \
		--build-arg UID="$(UID_IN_DOCKER)" \
		--build-arg GID="$(GID_IN_DOCKER)" \
		.
shell:
	docker exec -u root \
		-it "$(CONTAINER)" \
		/bin/bash

update:
	docker cp files/run-pb-server "$(CONTAINER)":/usr/local/bin/.
	docker exec -u root -it "$(CONTAINER)" chmod +x /usr/local/bin/run-pb-server
	docker cp files/fix-ids-in-container "$(CONTAINER)":/usr/local/bin/.
	docker exec -u root -it "$(CONTAINER)" chmod +x /usr/local/bin/fix-ids-in-container

fix_ids:
	docker exec -u root -it "$(CONTAINER)" /usr/local/bin/fix-ids-in-container $$(id -u $(DOCKER_USER)) $$(id -g $(DOCKER_USER))

