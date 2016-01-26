include builder/make/helpers.mk

# UID and GID of owner of src directory
UID=$(shell stat -c "%u" src)
GID=$(shell stat -c "%g" src)

# Check required variables
$(call check_defined, UID, user UID not set)
$(call check_defined, GID, user GID not set)
$(call check_defined, PROJECT, project name not set)
$(call check_defined, IMGBASE, base path for docker image name not set)
$(call check_defined, DEVPORT, port for development web server not set)
$(call check_defined, PRODPORT, port for production web server not set)

ROOT=$(shell pwd)
MO=$(ROOT)/builder/scripts/mo
BUILD_DIR=$(ROOT)/.build
TMPL_DIR=$(ROOT)/builder/templates
PROJECT_SRC=src/$(PROJECT)

export UID
export GID
export PROJECT
export IMGBASE
export DEVPORT
export PRODPORT
export ROOT
export BUILD_DIR


.PHONY: \
	info \
	init \
	shell \
	web \
	remove-images

#################
# Initialization
#################

GENERATED=$(addprefix $(BUILD_DIR)/, \
	docker/init-vue/Dockerfile \
	docker/shell/Dockerfile \
	docker/web/Dockerfile \
	docker/web/default.conf \
	info.md \
)

DOCKER_IMAGES=$(addprefix $(IMGBASE)/$(PROJECT)-, \
	init-vue \
	shell \
	web \
)

.PHONY: $(DOCKER_IMAGES)

init: $(GENERATED) $(DOCKER_IMAGES) $(PROJECT_SRC)

$(PROJECT_SRC):
	$(call infoblue,generating project source code)
	@-docker run -it --rm \
		-v $(ROOT)/src:/home/devuser/src \
		$(IMGBASE)/$(PROJECT)-init-vue

$(GENERATED): $(BUILD_DIR)/%: $(TMPL_DIR)/%
	$(call infoblue,generating $*)
	@mkdir -p $(dir $@)
	@$(MO) "$<" > "$@"

$(DOCKER_IMAGES): $(IMGBASE)/$(PROJECT)-%: $(BUILD_DIR)/docker/%
	$(call infoblue,building docker image $@)
	@docker build -t $@ $<

#################
# Working tasks
#################

shell:
	@docker run -it --rm \
		--hostname="$(PROJECT)-shell" \
		-v $(ROOT)/src:/home/devuser/src \
		-p $(DEVPORT):8080 \
		$(IMGBASE)/$(PROJECT)-shell

web:
	@docker run -it --rm \
		-v $(ROOT)/src:/home/devuser/src \
		-p $(PRODPORT):8080 \
		$(IMGBASE)/$(PROJECT)-web

##################
# Additional tasks
##################

info:
	@cat $(BUILD_DIR)/info.md

remove-images:
	docker rmi $(DOCKER_IMAGES)
