# Create AWS infra and deploy static site

```sh
aws cloudformation create-stack --stack-name my-s3-website-stack --template-body file://template.yml --parameters ParameterKey=BucketName,ParameterValue=rey-playground-cf-deploy --capabilities CAPABILITY_IAM
aws cloudformation delete-stack --stack-name my-s3-website-stack
aws cloudformation describe-stacks --stack-name my-s3-website-stack
aws cloudformation describe-stack-events --stack-name my-s3-website-stack
```

```sh
docker run --rm -it -v ~/.aws:/root/.aws -v $(pwd):/workspace --name aws-update-role aws-test:cl iam update-assume-role-policy --role-name GitHubActions-S3-Deploy-Role --policy-document file:///workspace/trust-policy.json
```

create stack:
aws cloudformation create-stack --stack-name my-s3-website-stack --template-body file://template.yml --parameters ParameterKey=BucketName,ParameterValue=rey-playground-cf-deploy --capabilities CAPABILITY_IAM --profile deployer

copy to s3:
pn aws s3 ls s3://rey-playground-cf-deploy --profile deployer

empty s3:
pn aws s3 rm s3://rey-playground-cf-deploy --recursive --profile deployer