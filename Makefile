
SCRIPTS=$(wildcard scripts/*.sh)

.PHONY: deps install enable lint test package

deps:
	@echo "Installing dependencies (jq, awscli, docker, kubectl, shellcheck)..."

install:
	@echo "Installing scripts to /usr/local/bin..."
	@cp scripts/*.sh /usr/local/bin/

enable:
	@echo "Enabling systemd services..."
	@cp systemd/* /etc/systemd/system/

lint:
	shellcheck $(SCRIPTS)

test:
	bash -n $(SCRIPTS)

package:
	zip -r devops-scripts-$(shell date +%Y%m%d%H%M).zip .
