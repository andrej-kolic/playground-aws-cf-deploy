### Docker AWS: run: version
```sh
docker run --rm -it public.ecr.aws/aws-cli/aws-cli --version
```

### Docker AWS: build image
```sh
docker build -t aws-test:cl .
```

### Docker: remove orphans
```sh
docker-compose down --remove-orphans
```

### Docker AWS: other
```sh
docker run -it --entrypoint /bin/sh aws-test:cl
docker run -it --entrypoint "" aws-test:cl aws --version
docker run -it --entrypoint "" aws-test:cl ls -la /app
docker run -it -v ~/.aws:/root/.aws aws-test:cl ls -la /app
docker compose up --build
```

```sh
aws cloudformation create-stack --stack-name my-s3-website-stack --template-body file://template.yml --parameters ParameterKey=BucketName,ParameterValue=rey-playground-cf-deploy --capabilities CAPABILITY_IAM
aws cloudformation delete-stack --stack-name my-s3-website-stack
aws cloudformation describe-stacks --stack-name my-s3-website-stack
aws cloudformation describe-stack-events --stack-name my-s3-website-stack
```

```sh
docker run --rm -it -v ~/.aws:/root/.aws -v $(pwd):/workspace --name aws-update-role aws-test:cl iam update-assume-role-policy --role-name GitHubActions-S3-Deploy-Role --policy-document file:///workspace/trust-policy.json
```