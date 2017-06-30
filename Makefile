all: deploy

terraform_version = "0.9.8"
terraform_url = "https://releases.hashicorp.com/terraform/$(terraform_version)/terraform_$(terraform_version)_linux_amd64.zip"
settings_file = $(environment)-$(region).tfvars
found = $(shell if [ -f "$$PWD/terraform" ];then echo "found";fi)
state_bucket = "y-tf-state"

set-env:
	@if [ -z $(environment) ]; then echo "Target environment was not set"; exit 10; fi
	@if [ -z $(region) ]; then echo "Target deployment region was not set"; exit 10; fi
	@if [ -z $(build) ]; then echo "Build was not set"; exit 10; fi
	@if [ -z $(found) ]; then curl -s $(terraform_url) > tf.zip && unzip -qo tf.zip && rm tf.zip; fi

init: set-env
	@./terraform --version | head -1
	@./terraform init -force-copy -backend=true \
		-backend-config="bucket=${state_bucket}" \
		-backend-config="key=/state/${environment}/dd-metrics-${region}.tfstate"

plan: init
	@./terraform plan -var-file=$(environment)-$(region).tfvars -var 'build="$(build)"'

deploy: init
	@./terraform taint -allow-missing aws_instance.ec2-instance
	@./terraform apply -var-file=$(environment)-$(region).tfvars -var 'build="$(build)"' -var 'region=$(region)'; result=$$?; exit $$result

destroy: init
	@./terraform destroy -var-file=$(environment)-$(region).tfvars -var

show: init
	@./terraform show

graph: init
	@./terraform graph -draw-cycles | dot -Tpng > graph.png

test:
	echo "z.yakaas.counter:1234|c" | nc -w0 -u $(shell ./find_ip.sh) 8125

.PHONY: all deploy init set-env destroy graph test
