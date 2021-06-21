.ONESHELL:
	SHELL := /bin/bash

init:
	@terraform init

apply: init
	@terraform apply \
		-var-file=hcloud.tfvars

destroy: init
	@terraform destroy \
		-var-file=hcloud.tfvars
