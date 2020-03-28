up:
	make build-back
	make up-back

up-%:
	docker-compose up $(subst up-,,$@)

build-%:
	docker-compose build $(subst build-,,$@)
