#!/bin/bash

ECR_REPO="dropwizard"
AWS_ACCOUNT_ID="XXXXXXXXXX"
REGION="eu-west-1"

docker build -t $ECR_REPO .
aws ecr get-login --no-include-email --region ${REGION}

docker tag $ECR_REPO:latest $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest

