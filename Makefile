all: deploy

terraform_version = "0.9.8"
os = `echo $(shell uname) | tr A-Z a-z`

terraform_url = "https://releases.hashicorp.com/terraform/$(terraform_version)/terraform_$(terraform_version)_$(os)_amd64.zip"

settings_file = $(TF_VAR_environment)-$(TF_VAR_region).tfvars
state_bucket = "y-tf-state"

found = $(shell if [ -f "$$PWD/terraform" ];then echo "found";fi)

set-env:
	@if [ -z $(TF_VAR_environment) ]; then echo "Target environment was not set"; exit 10; fi
	@if [ -z $(TF_VAR_region) ]; then echo "Target deployment region was not set"; exit 10; fi
	@if [ -z $(TF_VAR_build) ]; then echo "Build was not set"; exit 10; fi
	@if [ -z $(found) ]; then curl -s $(terraform_url) > tf.zip && unzip -qo tf.zip && rm tf.zip; fi

init: set-env
	@./terraform --version | head -1
	@./terraform init -force-copy -backend=true \
		-backend-config="bucket=${state_bucket}" \
		-backend-config="key=/state/${environment}/dd-metrics-${region}.tfstate"

plan: init
	@./terraform plan -var-file=$(settings_file)

deploy: init
	@./terraform taint -allow-missing aws_instance.ec2-instance
	@./terraform apply -var-file=$(settings_file); result=$$?; exit $$result

destroy: init
	@./terraform destroy -var-file=$(settings_file)

show: init
	@./terraform show

graph: init
	@./terraform graph -draw-cycles | dot -Tpng > graph.png

test:
	echo "z.yakaas.counter:1234|c" | nc -w0 -u $(shell ./find_ip.sh) 8125

.PHONY: all deploy init set-env destroy graph test
