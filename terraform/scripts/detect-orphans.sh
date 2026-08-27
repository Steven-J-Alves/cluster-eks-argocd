#!/usr/bin/env bash
# detect-orphans.sh — scan AWS for resources with our project tag
# and cross-check against what's in the current Terraform state.
#
# An orphan = tagged as ours, exists in AWS, NOT in Terraform state.
# Cause: previous apply/destroy left dangling resources, state got out of sync,
# or resources were created before/after a state reset.
#
# Usage:  AWS_PROFILE=steven-prod REGION=us-east-1 ./detect-orphans.sh

set -euo pipefail

: "${AWS_PROFILE:=steven-prod}"
: "${REGION:=us-east-1}"
: "${PROJECT_TAG:=DemoApp}"
STATE_DIR="$(cd "$(dirname "$0")/.." && pwd)/cluster"

echo "=== Scanning AWS ($REGION) for resources tagged Project=$PROJECT_TAG ==="

echo
echo "-- EC2 instances --"
aws ec2 describe-instances --region "$REGION" \
  --filters "Name=tag:Project,Values=$PROJECT_TAG" "Name=instance-state-name,Values=running,stopped,pending" \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`]|[0].Value]' --output text

echo
echo "-- VPCs --"
aws ec2 describe-vpcs --region "$REGION" \
  --filters "Name=tag:Project,Values=$PROJECT_TAG" \
  --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`]|[0].Value]' --output text

echo
echo "-- NAT Gateways --"
aws ec2 describe-nat-gateways --region "$REGION" \
  --filter "Name=state,Values=available,pending" \
  --query 'NatGateways[*].[NatGatewayId,VpcId]' --output text

echo
echo "-- EIPs (all) --"
aws ec2 describe-addresses --region "$REGION" \
  --query 'Addresses[*].[PublicIp,AllocationId,AssociationId]' --output text

echo
echo "-- EKS clusters --"
aws eks list-clusters --region "$REGION" --output text

echo
echo "-- RDS clusters --"
aws rds describe-db-clusters --region "$REGION" \
  --query 'DBClusters[*].DBClusterIdentifier' --output text

echo
echo "-- Lambda functions matching prod-* --"
aws lambda list-functions --region "$REGION" \
  --query 'Functions[?starts_with(FunctionName,`prod-`)].FunctionName' --output text

echo
echo "-- SQS queues --"
aws sqs list-queues --region "$REGION" 2>/dev/null || echo "  (none)"

echo
echo "-- ECR repos prod/* --"
aws ecr describe-repositories --region "$REGION" \
  --query 'repositories[?starts_with(repositoryName,`prod/`)].repositoryName' --output text

echo
echo "-- DynamoDB tables matching prod-* --"
aws dynamodb list-tables --region "$REGION" \
  --query 'TableNames[?starts_with(@,`prod-`)]' --output text

echo
echo "-- S3 buckets prod-app-* --"
aws s3api list-buckets --query 'Buckets[?starts_with(Name,`prod-app-`)].Name' --output text

echo
echo "=== What Terraform state knows about ==="
if [ -f "$STATE_DIR/.terraform/terraform.tfstate" ] || command -v terraform >/dev/null; then
  (cd "$STATE_DIR" && terraform state list 2>/dev/null | wc -l | xargs echo "  resources in state:")
else
  echo "  (state not initialised locally — run 'terraform init' first)"
fi

echo
echo "=== Done — anything above that is NOT in state = ORPHAN ==="
