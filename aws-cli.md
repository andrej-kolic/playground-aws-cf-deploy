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
