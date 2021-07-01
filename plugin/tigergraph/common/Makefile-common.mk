#
# Copyright 2020-2021 Xilinx, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

.DELETE_ON_ERROR:
.PHONY: all

#all: javaApi cppBuild javaTest stage
all: stage

#
# Global Definitions
#

## Location of graphanalytics project
GRAPH_ANALYTICS_DIR = ../..

# Location of TigerGraph Plugin common files
TG_PLUGIN_COMMON_DIR = ../common

#######################################################################################################################
#
# Staging
#

STAGE_DIR = staging

define STAGE_COPY_RULE
$$(STAGE_DIR)/$(1): $(1)
	cp -f $(1) $$(STAGE_DIR)/$(1)
endef
$(foreach f,$(STAGE_COPY_FILES),$(eval $(call STAGE_COPY_RULE,$(f),)))

# Files to be direct-copied from TigerGraph plugin common source tree to staging area

STAGE_COPY_COMMON_FILES = \
    install.sh \
    \
    bin/common.sh \
	bin/gen-cluster-info.py \
    bin/install-plugin-cluster.sh \
    bin/install-plugin-node.sh\
    \
    udf/mergeHeaders.py \
    udf/prepExprFunctions.py

define STAGE_COPY_COMMON_RULE
$$(STAGE_DIR)/$(1): $(TG_PLUGIN_COMMON_DIR)/$(1)
	cp -f $(TG_PLUGIN_COMMON_DIR)/$(1) $$(STAGE_DIR)/$(1)
endef
$(foreach f,$(STAGE_COPY_COMMON_FILES),$(eval $(call STAGE_COPY_COMMON_RULE,$(f),)))

# Files to be direct-copied from TigerGraph plugin common EXAMPLES source tree to staging area

TG_PLUGIN_COMMON_EXAMPLES_DIR = $(TG_PLUGIN_COMMON_DIR)/examples

STAGE_COPY_COMMON_EXAMPLES_FILES = \
    bin/common-udf.sh \
    bin/install-udf.sh \
    bin/install-udf-cluster.sh \
    bin/install-udf-node.sh

STAGE_ALL_COMMON_EXAMPLES_FILES =

define STAGE_COPY_COMMON_EXAMPLES_FILE_RULE
$(STAGE_DIR)/$(2)/$(1): $(TG_PLUGIN_COMMON_EXAMPLES_DIR)/$(1)
	cp -f $(TG_PLUGIN_COMMON_EXAMPLES_DIR)/$(1) $(STAGE_DIR)/$(2)/$(1)
STAGE_ALL_COMMON_EXAMPLES_FILES += $(STAGE_DIR)/$(2)/$(1)
endef

define STAGE_COPY_COMMON_EXAMPLES_RULE
$(foreach f,$(STAGE_COPY_COMMON_EXAMPLES_FILES),$(eval $(call STAGE_COPY_COMMON_EXAMPLES_FILE_RULE,$(f),$(1))))
endef

$(foreach edir,$(STAGE_EXAMPLES_DIRS),$(eval $(call STAGE_COPY_COMMON_EXAMPLES_RULE,$(edir))))

# Top-level packaging rule

STAGE_ALL_FILES = \
    $(addprefix $(STAGE_DIR)/,$(STAGE_COPY_FILES)) \
    $(addprefix $(STAGE_DIR)/,$(STAGE_COPY_COMMON_FILES)) \
    $(STAGE_ALL_COMMON_EXAMPLES_FILES)

STAGE_SUBDIRS = $(sort $(dir $(STAGE_ALL_FILES)))

stage: $(STAGE_DIR) $(STAGE_SUBDIRS) $(STAGE_ALL_FILES)


$(STAGE_DIR):
	mkdir -p $@

$(STAGE_SUBDIRS):
	mkdir -p $@

#######################################################################################################################
#
# Packaging
#

OSDIST = $(shell lsb_release -si)
DIST_TARGET =
ifeq ($(OSDIST),Ubuntu)
    DIST_TARGET = DEB
else ifeq ($(OSDIST),CentOS)
    DIST_TARGET = RPM
endif

all : install

.PHONY: dist

dist: stage
	@cd package; \
	if [ "$(DIST_TARGET)" == "" ]; then \
	    echo "Packaging is supported for only Ubuntu and CentOS."; \
	else \
	    echo "Packaging $(DIST_TARGET) for $(OSDIST)"; \
	    make ; \
	fi

ifdef sshKey
    SSH_KEY_OPT=-i $(sshKey)
endif

.PHONY: install
install: stage
	./staging/install.sh $(SSH_KEY_OPT)

#######################################################################################################################
#
# Clean
#

#### Clean target deletes all generated files ####
.PHONY: clean

clean:
	rm -rf $(STAGE_DIR)

help:
	@echo "Valid make targets:"
	@echo "stage   : Generate staging directory"
	@echo "dist    : Generate installation package (RPM or DEB) for the current OS and architecture"
	@echo "install : Make stage and run insta.sh"
	@echo ""
	@echo "Examples:"
	@echo "Install plugin files with SSH key file"
	@echo "make sshKey=~/.ssh/tigergraph_rsa"
