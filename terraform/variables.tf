provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  max_retries = "10"
}

variable "aws_key_name" {
  default = "test"
}

variable "aws_profile" {
  default = "default"
}

variable "aws_region" {
  default = "eu-west-1"
}


variable "dropwizard_ecr_image" {
  type = "string"
  default = "dropwizard/dropwizard-ci"
}


variable "cidr_base" {
  default = "70.31"
}

variable "image_name" {}