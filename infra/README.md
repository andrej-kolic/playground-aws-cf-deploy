# AWS CloudFormation Infrastructure

This directory contains comprehensive CloudFormation templates and deployment scripts to replicate the infrastructure used in the AWS CF Deploy project.

## 📁 Directory Structure

```
infra/
├── README.md                     # This file
├── iam-roles.yml                 # IAM roles and policies for GitHub Actions
├── s3-website.yml                # S3 bucket and CloudFront for static website hosting
├── deploy.sh                     # Deployment script with multiple options
└── github-actions-workflow.yml   # Complete GitHub Actions CI/CD workflow
```

## 🏗️ Infrastructure Components

### 1. IAM Roles and Policies (`iam-roles.yml`)

**Resources Created:**
- GitHub OIDC Identity Provider
- IAM Role for GitHub Actions with comprehensive S3 and CloudFormation permissions
- IAM Policy with granular permissions for:
  - CloudFormation operations (create, update, delete stacks)
  - S3 bucket management (create, delete, configure)
  - S3 object operations (upload, download, delete)
  - CloudFront distribution management
  - IAM role assumption for service operations

**Key Features:**
- Supports both GitHub Actions OIDC and direct admin user access
- Comprehensive permissions for all operations encountered in this project
- Proper resource-based access controls
- Environment-based tagging

### 2. S3 Website Hosting (`s3-website.yml`)

**Resources Created:**
- S3 Bucket configured for static website hosting
- S3 Bucket Policy for public read access
- CloudFront Distribution for CDN and HTTPS
- CloudFront Origin Access Identity for secure S3 access

**Key Features:**
- Versioning enabled on S3 bucket
- CORS configuration for cross-origin requests
- CloudFront with custom error pages (SPA support)
- Comprehensive caching policies
- Environment-based resource naming
- Export values for cross-stack references

## 🚀 Deployment Options

### Option 1: Using the Deployment Script (Recommended)

The `deploy.sh` script provides a comprehensive deployment solution with multiple commands:

```bash
# Make the script executable
chmod +x deploy.sh

# Deploy all infrastructure
./deploy.sh deploy-all

# Deploy only IAM components
./deploy.sh deploy-iam

# Deploy only website infrastructure
./deploy.sh deploy-website

# Check deployment status
./deploy.sh status

# View stack outputs
./deploy.sh outputs

# Destroy all infrastructure
./deploy.sh destroy
```

**Script Options:**
```bash
./deploy.sh [OPTIONS] COMMAND

Options:
  -r, --region REGION       AWS region (default: eu-west-1)
  -p, --profile PROFILE     AWS profile (default: default)
  -e, --environment ENV     Environment (default: dev)
  -o, --github-org ORG      GitHub organization (default: andrej-kolic)
  -R, --github-repo REPO    GitHub repository (default: *)
  -b, --bucket-name NAME    S3 bucket name (default: rey-playground-cf-deploy-{env})
```

**Examples:**
```bash
# Deploy to production
./deploy.sh -e prod -b my-prod-website deploy-all

# Deploy to staging with specific region
./deploy.sh -e staging -r us-west-2 deploy-all

# Deploy with custom GitHub settings
./deploy.sh -o my-org -R my-repo deploy-iam
```

### Option 2: Manual CloudFormation Deployment

#### Step 1: Deploy IAM Infrastructure
```bash
aws cloudformation create-stack \
  --stack-name aws-cf-deploy-iam-dev \
  --template-body file://iam-roles.yml \
  --parameters \
    ParameterKey=GitHubOrg,ParameterValue=andrej-kolic \
    ParameterKey=GitHubRepo,ParameterValue="*" \
    ParameterKey=Environment,ParameterValue=dev \
  --capabilities CAPABILITY_NAMED_IAM \
  --region eu-west-1
```

#### Step 2: Deploy Website Infrastructure
```bash
aws cloudformation create-stack \
  --stack-name aws-cf-deploy-website-dev \
  --template-body file://s3-website.yml \
  --parameters \
    ParameterKey=BucketName,ParameterValue=rey-playground-cf-deploy-dev \
    ParameterKey=Environment,ParameterValue=dev \
  --region eu-west-1
```

### Option 3: GitHub Actions CI/CD

The `github-actions-workflow.yml` provides a complete CI/CD pipeline:

1. **Copy the workflow file** to `.github/workflows/deploy.yml` in your repository
2. **Set up repository secrets**:
   - `AWS_ROLE_ARN`: ARN of the GitHub Actions role (from IAM stack output)
3. **Configure environments** in GitHub repository settings (dev, staging, prod)
4. **Push to main branch** or manually trigger deployment

**Workflow Features:**
- Template validation
- Multi-environment deployment
- Automatic content deployment to S3
- CloudFront cache invalidation
- Pull request cleanup
- Manual deployment triggers

## 🔧 Configuration

### Environment Variables

The deployment script supports these environment variables:

```bash
export AWS_REGION=eu-west-1
export AWS_PROFILE=default
export ENVIRONMENT=dev
export GITHUB_ORG=andrej-kolic
export GITHUB_REPO="*"
export BUCKET_NAME=rey-playground-cf-deploy-dev
```

### Parameter Customization

Both templates support the following parameters:

**IAM Template:**
- `GitHubOrg`: GitHub organization or username
- `GitHubRepo`: Repository name (use `*` for all repos)
- `Environment`: Environment name (dev/staging/prod)

**Website Template:**
- `BucketName`: S3 bucket name (must be globally unique)
- `Environment`: Environment name for tagging

## 📊 Stack Outputs

### IAM Stack Outputs
- `GitHubActionsRoleArn`: IAM role ARN for GitHub Actions
- `GitHubOIDCProviderArn`: OIDC provider ARN
- `CloudFormationServiceRoleArn`: Service role for CloudFormation
- `PolicyArn`: Custom policy ARN

### Website Stack Outputs
- `WebsiteURL`: S3 static website URL
- `BucketName`: S3 bucket name
- `CloudFrontURL`: CloudFront distribution URL (recommended)
- `CloudFrontDistributionId`: Distribution ID for cache invalidation
- `BucketArn`: S3 bucket ARN

## 🔍 Troubleshooting

### Common Issues

1. **Bucket name already exists**
   - S3 bucket names are globally unique
   - Use a different bucket name with the `-b` option

2. **IAM permissions insufficient**
   - Ensure your AWS credentials have sufficient permissions
   - The deploying user needs IAM, S3, and CloudFormation permissions

3. **Stack already exists**
   - Use `update-stack` instead of `create-stack`
   - Or use the deployment script which handles both cases

4. **CloudFormation stack deletion fails**
   - Empty S3 bucket before deleting stack
   - Use `./deploy.sh destroy` which handles cleanup properly

### Validation Commands

```bash
# Validate templates
aws cloudformation validate-template --template-body file://iam-roles.yml
aws cloudformation validate-template --template-body file://s3-website.yml

# Check stack status
aws cloudformation describe-stacks --stack-name aws-cf-deploy-iam-dev
aws cloudformation describe-stacks --stack-name aws-cf-deploy-website-dev
```

## 🏷️ Resource Tagging

All resources are tagged with:
- `Environment`: Environment name (dev/staging/prod)
- `Project`: aws-cf-deploy
- `ManagedBy`: CloudFormation or GitHub-Actions
- `Purpose`: Resource-specific purpose

## 🔐 Security Considerations

1. **IAM Roles**: Follow principle of least privilege
2. **S3 Bucket**: Public read access is configured for website hosting
3. **CloudFront**: HTTPS redirect enforced
4. **GitHub Actions**: Uses OIDC for secure authentication
5. **Resource Access**: Scoped to specific bucket patterns where possible

## 🚀 Getting Started

1. **Clone this repository**
2. **Navigate to infra directory**: `cd infra`
3. **Configure AWS credentials**: `aws configure`
4. **Run deployment**: `./deploy.sh deploy-all`
5. **Deploy your website content** to the created S3 bucket
6. **Access your website** via the CloudFront URL

## 📚 Additional Resources

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [GitHub Actions AWS Integration](https://docs.github.com/en/actions/deployment/deploying-to-aws)
- [S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)

---

**Note**: This infrastructure setup replicates and enhances the manual configuration used in the AWS CF Deploy project, providing a production-ready, automated deployment solution.

