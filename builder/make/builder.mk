include builder/make/helpers.mk

# UID and GID of owner of src directory
UID=$(shell stat -c "%u" src)
GID=$(shell stat -c "%g" src)

# Check required variables
$(call check_defined, UID, user UID not set)
$(call check_defined, GID, user GID not set)
$(call check_defined, PROJECT, project name not set)
$(call check_defined, BASENAME, base path for docker image name not set)
$(call check_defined, DEVPORT, port for development web server not set)
$(call check_defined, DISTPORT, port for production web server not set)

ROOT=$(shell pwd)
MO=$(ROOT)/builder/scripts/mo
BUILD_DIR=$(ROOT)/.build
TMPL_DIR=$(ROOT)/builder/templates
SRC_DIR=$(ROOT)/src
PROJECT_SRC=src/$(PROJECT)

export UID
export GID
export PROJECT
export BASENAME
export DEVPORT
export DISTPORT
export ROOT
export BUILD_DIR
export SRC_DIR

COMPOSE_VERSION=1.5.2
COMPOSE_CURL=curl -L https://github.com/docker/compose/releases/download/$(COMPOSE_VERSION)/docker-compose-`uname -s`-`uname -m`
COMPOSE_BIN=$(ROOT)/builder/scripts/docker-compose-$(COMPOSE_VERSION)

COMPOSE_DIR=$(ROOT)/builder/compose
COMPOSE_CMD=$(COMPOSE_BIN) --project-name $(PROJECT)
COMPOSE_INIT_CMD=$(COMPOSE_CMD) $(addprefix -f $(COMPOSE_DIR)/, init.yml)
COMPOSE_COMMANDS_CMD=$(COMPOSE_CMD) $(addprefix -f $(COMPOSE_DIR)/, commands.yml)
COMPOSE_SERVICES_CMD=$(COMPOSE_CMD) $(addprefix -f $(COMPOSE_DIR)/, services.yml)

GENERATED=$(addprefix $(BUILD_DIR)/, \
	info.md \
	docker/dist/default.conf \
)

# ordering is IMPORTANT!
DOCKERFILES=$(addsuffix /Dockerfile,$(addprefix $(BUILD_DIR)/docker/, \
	shell \
	dist \
))

BUILDER_FILES=\
	Makefile \
	builder/make/builder.mk \
	builder/make/helpers.mk

### TARGETS

.DEFAULT_GOAL := start

.PHONY: \
	prepare \
	info \
	shell \
	dist \
	clean

$(COMPOSE_BIN):
	$(COMPOSE_CURL) > "$@"
	chmod +x $@

$(DOCKERFILES): $(BUILDER_FILES) $(GENERATED)

$(DOCKERFILES): $(BUILD_DIR)/docker/%/Dockerfile: $(TMPL_DIR)/docker/%/Dockerfile
	$(call infoblue,generating $*/Dockerfile)
	@mkdir -p $(dir $@)
	@$(MO) "$<" > "$@"
	$(call infoblue,building docker image $(BASENAME)/$(PROJECT)-$*)
	docker build -t $(BASENAME)/$(PROJECT)-$* $(dir $@)

$(GENERATED): $(BUILDER_FILES)

$(GENERATED): $(BUILD_DIR)/%: $(TMPL_DIR)/%
	$(call infoblue,generating $*)
	@mkdir -p $(dir $@)
	@$(MO) "$<" > "$@"

$(PROJECT_SRC):
	$(call infoblue,generating project source code)
	@$(COMPOSE_INIT_CMD) run --service-ports --rm init

prepare: $(COMPOSE_BIN) $(DOCKERFILES)

info:
	$(call infoblue,INFO)
	@echo "Development web server : http://localhost:$(WEBPORT)"
	@echo "Dist web server        : http://localhost:$(DBADMINPORT)"

shell: prepare $(PROJECT_SRC)
	$(call infoblue,opening shell in container $(BASENAME)_$(PROJECT)-shell)
	@$(COMPOSE_COMMANDS_CMD) run --service-ports --rm shell

dist:
	$(call infoblue,starting services: $(SERVICES))
	@$(COMPOSE_SERVICES_CMD) up --force-recreate dist

clean:
	$(call infoblue,stopping containers: dist shell)
	@$(COMPOSE_COMMANDS_CMD) stop shell
	@$(COMPOSE_SERVICES_CMD) stop dist
	$(call infoblue,removing containers: dist shell)
	@$(COMPOSE_COMMANDS_CMD) rm -v --force shell
	@$(COMPOSE_SERVICES_CMD) rm -v --force dist
	$(call infoblue,removing dirs: $(BUILD_DIR))
	@rm -rf $(BUILD_DIR)


#
# .PHONY: \
# 	info \
# 	init \
# 	shell \
# 	web \
# 	remove-images
#
# #################
# # Initialization
# #################
#
# GENERATED=$(addprefix $(BUILD_DIR)/, \
# 	docker/init-vue/Dockerfile \
# 	docker/shell/Dockerfile \
# 	docker/web/Dockerfile \
# 	docker/web/default.conf \
# 	info.md \
# )
#
# DOCKER_IMAGES=$(addprefix $(BASENAME)/$(PROJECT)-, \
# 	init-vue \
# 	shell \
# 	web \
# )
#
# .PHONY: $(DOCKER_IMAGES)
#
# init: $(GENERATED) $(DOCKER_IMAGES) $(PROJECT_SRC)
#
# $(PROJECT_SRC):
# 	$(call infoblue,generating project source code)
# 	@-docker run -it --rm \
# 		-v $(ROOT)/src:/home/devuser/src \
# 		$(BASENAME)/$(PROJECT)-init-vue
#
# $(GENERATED): $(BUILD_DIR)/%: $(TMPL_DIR)/%
# 	$(call infoblue,generating $*)
# 	@mkdir -p $(dir $@)
# 	@$(MO) "$<" > "$@"
#
# $(DOCKER_IMAGES): $(BASENAME)/$(PROJECT)-%: $(BUILD_DIR)/docker/%
# 	$(call infoblue,building docker image $@)
# 	@docker build -t $@ $<
#
# #################
# # Working tasks
# #################
#
# shell:
# 	@docker run -it --rm \
# 		--hostname="$(PROJECT)-shell" \
# 		-v $(ROOT)/src:/home/devuser/src \
# 		-p $(DEVPORT):8080 \
# 		$(BASENAME)/$(PROJECT)-shell
#
# web:
# 	@docker run -it --rm \
# 		-v $(ROOT)/src:/home/devuser/src \
# 		-p $(PRODPORT):8080 \
# 		$(BASENAME)/$(PROJECT)-web
#
# ##################
# # Additional tasks
# ##################
#
# info:
# 	@cat $(BUILD_DIR)/info.md
#
# remove-images:
# 	docker rmi $(DOCKER_IMAGES)
