# 🚀 Deployment Multi-Stage con Helmfile, Terraform y CI/CD

Este proyecto despliega una imagen personalizada basada en [`nginxdemos/hello`](https://hub.docker.com/r/nginxdemos/hello/) en un clúster Kubernetes usando entornos separados (`dev`, `stage`). La configuración es modular y segura utilizando `Helmfile`, `helm-secrets`, `Terraform` y `GitLab CI`.

## 📁 Estructura del Proyecto

```plaintext
.
├── deploy/
│   ├── helmfile.yaml
│   ├── environments/
│   │   ├── dev.yaml
│   │   └── stage.yaml
│   ├── secrets/
│   │   ├── dev-secrets.yaml
│   └── charts/
│       └── hello-nginx/
│           ├── values.yaml
│           └── templates/
│               └── deployment.yaml
├── infra/
│   └── terraform/
│       └── eks/
│           └── main.tf
├── .gitlab-ci.yml
├── Dockerfile
└── .dockerignore
```

## 📦 Imagen personalizada

Agrega al HTML de la imagen la variable `ENVIRONMENT` y `SECRET_VALUE`.

```dockerfile
FROM nginxdemos/hello

ENV ENVIRONMENT=unknown
ENV SECRET_VALUE=none

RUN echo "<h1>Environment: $ENVIRONMENT</h1><h2>Secret: $SECRET_VALUE</h2>" >> /usr/share/nginx/html/index.html
```

## 🔐 Secretos con `helm-secrets`

```yaml
# deploy/secrets/dev-secrets.yaml
env:
  secretValue: "s3cr3t-dev"
```

```bash
sops -e dev-secrets.yaml > dev-secrets.yaml.dec
```

## 📄 Helmfile

```yaml
environments:
  dev:
    values:
      - environments/dev.yaml
      - secrets/dev-secrets.yaml.dec
  stage:
    values:
      - environments/stage.yaml
      - secrets/stage-secrets.yaml.dec

releases:
  - name: hello-nginx
    namespace: default
    chart: local/hello-nginx
    values:
      - values.yaml
```

## 🎯 Charts

```yaml
# values.yaml
image:
  repository: gonzag077/hello-nginx
  tag: latest

env:
  environment: dev
  secretValue: ""
```

```yaml
# deployment.yaml
env:
  - name: ENVIRONMENT
    value: "{{ .Values.env.environment }}"
  - name: SECRET_VALUE
    valueFrom:
      secretKeyRef:
        name: app-secret
        key: secretValue
```

## 🌐 Terraform para EKS

```hcl
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "demo-eks"
  ...
}
```

## 🔄 GitLab CI/CD

```yaml
stages:
  - build
  - deploy

build:
  script:
    - docker build -t $REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
    - docker push $REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

deploy:
  script:
    - export KUBECONFIG=$(terraform output -raw kubeconfig)
    - helmfile -e $CI_ENVIRONMENT_NAME apply
```

## 🧪 Comandos útiles

```bash
sops -e secrets/dev-secrets.yaml > secrets/dev-secrets.yaml.dec
helmfile -e dev apply
helmfile -e stage apply
```
