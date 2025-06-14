#!/bin/bash

# Infrastructure deployment script for AWS CF Deploy project
# This script deploys the complete infrastructure using CloudFormation

set -e

# Configuration
REGION=${AWS_REGION:-"eu-west-1"}
PROFILE=${AWS_PROFILE:-"default"}
ENVIRONMENT=${ENVIRONMENT:-"dev"}
GITHUB_ORG=${GITHUB_ORG:-"andrej-kolic"}
GITHUB_REPO=${GITHUB_REPO:-"*"}
BUCKET_NAME=${BUCKET_NAME:-"rey-playground-cf-deploy-${ENVIRONMENT}"}

# Stack names
IAM_STACK_NAME="aws-cf-deploy-iam-${ENVIRONMENT}"
WEBSITE_STACK_NAME="aws-cf-deploy-website-${ENVIRONMENT}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
}

check_stack_exists() {
    local stack_name=$1
    aws cloudformation describe-stacks \
        --stack-name "$stack_name" \
        --region "$REGION" \
        --profile "$PROFILE" \
        --output text \
        --query 'Stacks[0].StackStatus' 2>/dev/null || echo "DOES_NOT_EXIST"
}

wait_for_stack() {
    local stack_name=$1
    local operation=$2
    
    log_info "Waiting for stack $operation to complete..."
    
    aws cloudformation wait "stack-${operation}-complete" \
        --stack-name "$stack_name" \
        --region "$REGION" \
        --profile "$PROFILE"
    
    if [ $? -eq 0 ]; then
        log_success "Stack $operation completed successfully"
    else
        log_error "Stack $operation failed"
        exit 1
    fi
}

deploy_iam_stack() {
    log_info "Deploying IAM stack: $IAM_STACK_NAME"
    
    local stack_status
    stack_status=$(check_stack_exists "$IAM_STACK_NAME")
    
    if [ "$stack_status" = "DOES_NOT_EXIST" ]; then
        log_info "Creating new IAM stack..."
        aws cloudformation create-stack \
            --stack-name "$IAM_STACK_NAME" \
            --template-body file://iam-roles.yml \
            --parameters \
                ParameterKey=GitHubOrg,ParameterValue="$GITHUB_ORG" \
                ParameterKey=GitHubRepo,ParameterValue="$GITHUB_REPO" \
                ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$REGION" \
            --profile "$PROFILE" \
            --tags \
                Key=Environment,Value="$ENVIRONMENT" \
                Key=Project,Value=aws-cf-deploy \
                Key=ManagedBy,Value=CloudFormation
        
        wait_for_stack "$IAM_STACK_NAME" "create"
    else
        log_info "Updating existing IAM stack..."
        aws cloudformation update-stack \
            --stack-name "$IAM_STACK_NAME" \
            --template-body file://iam-roles.yml \
            --parameters \
                ParameterKey=GitHubOrg,ParameterValue="$GITHUB_ORG" \
                ParameterKey=GitHubRepo,ParameterValue="$GITHUB_REPO" \
                ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$REGION" \
            --profile "$PROFILE" \
            --tags \
                Key=Environment,Value="$ENVIRONMENT" \
                Key=Project,Value=aws-cf-deploy \
                Key=ManagedBy,Value=CloudFormation 2>/dev/null
        
        if [ $? -eq 0 ]; then
            wait_for_stack "$IAM_STACK_NAME" "update"
        else
            log_warning "No updates required for IAM stack"
        fi
    fi
}

deploy_website_stack() {
    log_info "Deploying website stack: $WEBSITE_STACK_NAME"
    
    local stack_status
    stack_status=$(check_stack_exists "$WEBSITE_STACK_NAME")
    
    if [ "$stack_status" = "DOES_NOT_EXIST" ]; then
        log_info "Creating new website stack..."
        aws cloudformation create-stack \
            --stack-name "$WEBSITE_STACK_NAME" \
            --template-body file://s3-website.yml \
            --parameters \
                ParameterKey=BucketName,ParameterValue="$BUCKET_NAME" \
                ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
            --region "$REGION" \
            --profile "$PROFILE" \
            --tags \
                Key=Environment,Value="$ENVIRONMENT" \
                Key=Project,Value=aws-cf-deploy \
                Key=ManagedBy,Value=CloudFormation
        
        wait_for_stack "$WEBSITE_STACK_NAME" "create"
    else
        log_info "Updating existing website stack..."
        aws cloudformation update-stack \
            --stack-name "$WEBSITE_STACK_NAME" \
            --template-body file://s3-website.yml \
            --parameters \
                ParameterKey=BucketName,ParameterValue="$BUCKET_NAME" \
                ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
            --region "$REGION" \
            --profile "$PROFILE" \
            --tags \
                Key=Environment,Value="$ENVIRONMENT" \
                Key=Project,Value=aws-cf-deploy \
                Key=ManagedBy,Value=CloudFormation 2>/dev/null
        
        if [ $? -eq 0 ]; then
            wait_for_stack "$WEBSITE_STACK_NAME" "update"
        else
            log_warning "No updates required for website stack"
        fi
    fi
}

get_outputs() {
    log_info "Retrieving stack outputs..."
    
    echo
    echo "=== IAM Stack Outputs ==="
    aws cloudformation describe-stacks \
        --stack-name "$IAM_STACK_NAME" \
        --region "$REGION" \
        --profile "$PROFILE" \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table
    
    echo
    echo "=== Website Stack Outputs ==="
    aws cloudformation describe-stacks \
        --stack-name "$WEBSITE_STACK_NAME" \
        --region "$REGION" \
        --profile "$PROFILE" \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] COMMAND

Commands:
  deploy-iam      Deploy only the IAM stack
  deploy-website  Deploy only the website stack
  deploy-all      Deploy both stacks
  destroy         Destroy all stacks
  outputs         Show stack outputs
  status          Show stack status

Options:
  -r, --region REGION       AWS region (default: eu-west-1)
  -p, --profile PROFILE     AWS profile (default: default)
  -e, --environment ENV     Environment (default: dev)
  -o, --github-org ORG      GitHub organization (default: andrej-kolic)
  -R, --github-repo REPO    GitHub repository (default: *)
  -b, --bucket-name NAME    S3 bucket name (default: rey-playground-cf-deploy-{env})
  -h, --help               Show this help

Environment Variables:
  AWS_REGION         AWS region
  AWS_PROFILE        AWS profile
  ENVIRONMENT        Environment name
  GITHUB_ORG         GitHub organization
  GITHUB_REPO        GitHub repository
  BUCKET_NAME        S3 bucket name

Examples:
  $0 deploy-all
  $0 -e prod -b my-prod-bucket deploy-all
  $0 --environment staging deploy-website
  $0 destroy

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -p|--profile)
            PROFILE="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -o|--github-org)
            GITHUB_ORG="$2"
            shift 2
            ;;
        -R|--github-repo)
            GITHUB_REPO="$2"
            shift 2
            ;;
        -b|--bucket-name)
            BUCKET_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        deploy-iam|deploy-website|deploy-all|destroy|outputs|status)
            COMMAND="$1"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if command is provided
if [ -z "$COMMAND" ]; then
    log_error "No command provided"
    show_usage
    exit 1
fi

# Update stack names with environment
IAM_STACK_NAME="aws-cf-deploy-iam-${ENVIRONMENT}"
WEBSITE_STACK_NAME="aws-cf-deploy-website-${ENVIRONMENT}"

# Main execution
log_info "Starting infrastructure deployment..."
log_info "Region: $REGION"
log_info "Profile: $PROFILE"
log_info "Environment: $ENVIRONMENT"
log_info "GitHub Org: $GITHUB_ORG"
log_info "GitHub Repo: $GITHUB_REPO"
log_info "Bucket Name: $BUCKET_NAME"
echo

check_aws_cli

case $COMMAND in
    deploy-iam)
        deploy_iam_stack
        get_outputs
        ;;
    deploy-website)
        deploy_website_stack
        get_outputs
        ;;
    deploy-all)
        deploy_iam_stack
        deploy_website_stack
        get_outputs
        ;;
    destroy)
        log_warning "This will destroy all infrastructure. Are you sure? (y/N)"
        read -r confirmation
        if [[ $confirmation =~ ^[Yy]$ ]]; then
            log_info "Destroying website stack..."
            aws cloudformation delete-stack \
                --stack-name "$WEBSITE_STACK_NAME" \
                --region "$REGION" \
                --profile "$PROFILE" 2>/dev/null || true
            
            log_info "Destroying IAM stack..."
            aws cloudformation delete-stack \
                --stack-name "$IAM_STACK_NAME" \
                --region "$REGION" \
                --profile "$PROFILE" 2>/dev/null || true
            
            log_success "Destruction initiated. Monitor in AWS Console."
        else
            log_info "Destruction cancelled."
        fi
        ;;
    outputs)
        get_outputs
        ;;
    status)
        echo "=== Stack Status ==="
        echo "IAM Stack: $(check_stack_exists "$IAM_STACK_NAME")"
        echo "Website Stack: $(check_stack_exists "$WEBSITE_STACK_NAME")"
        ;;
esac

log_success "Operation completed!"

