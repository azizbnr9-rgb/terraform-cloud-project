mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = { names = ["us-east-1a", "us-east-1b", "us-east-1c"] }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_data "aws_ssm_parameter" {
    defaults = { value = "ami-0123456789abcdef0" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_region" {
    defaults = { name = "us-east-1" }
  }
  mock_data "aws_elb_service_account" {
    defaults = { arn = "arn:aws:iam::127311923021:root" }
  }
  mock_resource "aws_db_instance" {
    defaults = { master_user_secret = [{ secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:x", kms_key_id = "k", secret_status = "active" }] }
  }
  mock_resource "aws_launch_template" {
    defaults = { id = "lt-0123456789abcdef0", latest_version = 1 }
  }
  mock_resource "aws_lb" {
    defaults = { arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/x/1", dns_name = "x.elb.amazonaws.com", arn_suffix = "app/x/1" }
  }
  mock_resource "aws_lb_target_group" {
    defaults = { arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/x/1", arn_suffix = "targetgroup/x/1" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/x", id = "x" }
  }
  mock_resource "aws_s3_bucket" {
    defaults = { arn = "arn:aws:s3:::cloud5-dev-assets" }
  }
}

run "plan_dev" {
  command = apply
  assert {
    condition     = length(module.network.app_subnet_ids) == 2
    error_message = "2 subnets app attendus"
  }
  assert {
    condition     = join(",", output.availability_zones) == "us-east-1a,us-east-1b"
    error_message = "AZ"
  }
}

run "plan_prod_like" {
  command = apply
  variables {
    single_nat_gateway = false
    create_iam_role    = true
    certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/abc"
  }
}
