### Docker AWS: run: version

```sh
docker run --rm -it public.ecr.aws/aws-cli/aws-cli --version
```


### Docker AWS: build image

```sh
docker build -t aws-test:1.0 .
```


### Docker AWS: other

```sh
docker run -it --entrypoint /bin/sh aws-test:1.0
docker run -it --entrypoint "" aws-test:1.0 aws --version
docker run -it --entrypoint "" aws-test:1.0 ls -la /app
docker compose up --build
```
