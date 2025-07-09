SERVICE=teste_api

build:
	docker compose build

up:
	docker compose run --rm $(SERVICE) /bin/sh

test:
	docker compose run --rm $(SERVICE) robot $(ROBOT_ARGS)