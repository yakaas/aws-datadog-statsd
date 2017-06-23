all: deploy

terraform_url = "https://releases.hashicorp.com/terraform/0.9.8/terraform_0.9.8_linux_amd64.zip"
state_bucket = "y-tf-state"

setup:
	@curl -s $(terraform_url) > tf.zip && unzip tf.zip && rm tf.zip

set-env:
	@if [ -z $(environment) ]; then echo "Target environment was not set"; exit 10; fi
	@if [ -z $(region) ]; then echo "Target deployment region was not set"; exit 10; fi
	@if [ -z $(build) ]; then echo "Build was not set"; exit 10; fi

init: set-env
	@./terraform --version | head -1
	@./terraform init -force-copy -backend=true \
		-backend-config="bucket=${state_bucket}" \
		-backend-config="key=/state/${environment}/dd-metrics-${region}.tfstate"

plan: init
	@./terraform plan -var-file=$(environment)-$(region).tfvars -var 'build="$(build)"'

deploy: init
	@./terraform taint -allow-missing aws_instance.ec2-instance
	@./terraform apply -var-file=$(environment)-$(region).tfvars -var 'build="$(build)"'; result=$$?; exit $$result

destroy: init
	@./terraform destroy -var-file=$(environment)-$(region).tfvars -var

show: init
	@./terraform show

graph: init
	@./terraform graph -draw-cycles | dot -Tpng > graph.png

test:
	echo "z.yakaas.counter:1234|c" | nc -w0 -u $(shell ./find_ip.sh) 8125

.PHONY: all deploy init set-env destroy graph test
