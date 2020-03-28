up:
	make up-front
	make up-back

build:
	make build-front
	make build-back

stop:
	docker-compose stop

up-%:
	docker-compose up -d $(subst up-,,$@)

build-%:
	docker-compose build $(subst build-,,$@)
