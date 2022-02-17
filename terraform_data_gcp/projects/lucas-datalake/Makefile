.DEFAULT_GOAL := plan
ENV=develop
init:
	terraform init -backend-config=config/${ENV}.conf;
plan:
	terraform plan -var-file=config/${ENV}.tfvars 
apply:
	terraform apply -var-file=config/${ENV}.tfvars  
destroy:
	terraform destroy -var-file=config/${ENV}.tfvars          
refresh:
	terraform refresh -var-file=config/${ENV}.tfvars      
fmt:
	terraform fmt --recursive
validade:
	terraform validate