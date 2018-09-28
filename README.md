# dropwizard 

a- Setting up environment and installing dependencies 


b- Dockerizing application / Creating dockerfile / pushing into ECR repo

  -AWS Cli needs to be installed and set 
  

Below variables will be set by login-ecr.sh file (it will create dokcerized app. , login into ECR and push image to ECR with latest tag)

ECR_REPO="dropwizard"

AWS_ACCOUNT_ID="XXXXXXXXXX"

REGION="eu-west-1"

c- Creating terraform ECS application  below comamands will create necessary resources in AWS

Terraform init

Terraform plan 

Terraform apply


Test :  Send request to     

ec2-ip-address:8080/hello-world
