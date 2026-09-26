# Laboratorio: EKS + Terraform + GitHub Actions

Este laboratorio crea `eks-lab-tec` en `us-east-1` con Terraform y GitHub Actions. Basado en el `cluster.yaml` de la clase: Kubernetes 1.35, OIDC/IRSA, 2-4 nodos t3.medium, 30 GB gp3, VPC CNI con Network Policies, EBS CSI y namespace `tech-store`. También deja integrado el AWS Load Balancer Controller mediante Terraform + Helm + IRSA.

> **Costos:** crea infraestructura real de AWS. Ejecuta `terraform destroy` al terminar.

## 1. Arquitectura

```text
GitHub -> Actions -> GitHub OIDC -> AWS IAM Role -> Terraform
                                                    |
                                      +-------------+-------------+
                                      |                           |
                                     VPC                         EKS
                                      |                           |
                             public/private subnets       2-4 x t3.medium
                                                                  |
                                                    +-------------+-------------+
                                                    |             |             |
                                                 VPC CNI       EBS CSI      tech-store
                                                                  |
                                                               IRSA/OIDC
                                                                  |
                                                     AWS Load Balancer Controller
                                                                  |
                                                                 ALB
```

## 2. Prerrequisitos

Instala/verifica:

```bash
aws --version
terraform version
kubectl version --client
helm version
git --version
```

Necesitas una cuenta AWS, un repositorio GitHub y permisos suficientes para el bootstrap.

Configura AWS localmente para el bootstrap:

```bash
aws configure
aws sts get-caller-identity
```

## 3. Bootstrap: ¿por qué existe?

GitHub Actions necesita un IAM Role para ejecutar Terraform, pero ese Role debe existir antes del primer pipeline. Por eso `bootstrap/` se ejecuta **una sola vez** desde tu PC.

Crea el S3 State, GitHub OIDC Provider y el Role de GitHub Actions.

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars`:

```hcl
aws_region = "us-east-1"
github_org = "TU-USUARIO-O-ORGANIZACION"
github_repo = "TU-REPOSITORIO"
state_bucket_name = "tfstate-eks-lab-tec-123456789012"
```

Luego:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Guarda el output `github_actions_role_arn` y el nombre del bucket.

> El Role del bootstrap usa `Action="*"` para simplificar la clase. Después puedes enseñar mínimo privilegio como una mejora.

## 4. Terraform del EKS

```bash
cd ../terraform
cp terraform.tfvars.example terraform.tfvars
```

Ajusta los valores si es necesario. Inicializa el backend S3:

```bash
terraform init \
  -backend-config="bucket=TU_BUCKET_DE_STATE" \
  -backend-config="key=eks-lab-tec/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="use_lockfile=true"
```

Valida:

```bash
terraform fmt -check -recursive
terraform validate
terraform plan
```

Para una prueba local:

```bash
terraform apply
```

## 5. ¿Qué crea Terraform?

- VPC con subnets públicas y privadas.
- EKS `eks-lab-tec`, Kubernetes `1.35`.
- Managed Node Group `workers` con 2 nodos iniciales, min 2, max 4.
- EC2 `t3.medium` y discos gp3 de 30 GB.
- VPC CNI con Network Policies.
- AWS EBS CSI Driver.
- OIDC/IRSA.
- Namespace `tech-store` con label `app.kubernetes.io/part-of=tech-store`.
- IAM Policy/Role y Helm Release del AWS Load Balancer Controller.

## 6. kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name eks-lab-tec
kubectl get nodes -o wide
kubectl get ns tech-store --show-labels
```

Si quieres demostrar el manifiesto Kubernetes de forma independiente:

```bash
kubectl apply -f ../k8s/namespace-tech-store.yaml
```

Por defecto el namespace también está gestionado por Terraform (`manage_namespace_with_terraform=true`). No lo gestiones simultáneamente por ambos mecanismos en una práctica real.

## 7. GitHub Actions

En GitHub: **Settings -> Secrets and variables -> Actions -> Variables** crea:

```text
AWS_REGION=us-east-1
TF_STATE_BUCKET=<bucket-del-bootstrap>
TF_STATE_KEY=eks-lab-tec/terraform.tfstate
AWS_ROLE_TO_ASSUME=arn:aws:iam::<ACCOUNT_ID>:role/github-actions-terraform-eks-lab
```

No se necesitan Access Keys. El workflow usa GitHub OIDC:

```yaml
permissions:
  id-token: write
  contents: read
```

El flujo es:

```text
Pull Request -> fmt -> init -> validate -> plan
main         -> fmt -> init -> validate -> apply
```

## 8. Validaciones

```bash
aws eks describe-cluster --name eks-lab-tec --region us-east-1 --query 'cluster.status'
aws eks list-addons --cluster-name eks-lab-tec --region us-east-1
kubectl get nodes
kubectl get ns tech-store --show-labels
kubectl get deployment aws-load-balancer-controller -n kube-system
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

## 9. AWS Load Balancer Controller

Tu material anterior usa `ingressClassName: alb`. En este proyecto ya no necesitas crear manualmente el IAM ServiceAccount con `eksctl`: Terraform crea Policy, Role, ServiceAccount y Helm Release. El flujo es:

```text
EKS OIDC -> IAM Role -> ServiceAccount -> Helm -> AWS Load Balancer Controller -> Ingress -> ALB
```

La política incluida corresponde al archivo oficial v2.14.1 usado en el material de clase.

## 10. Destruir

```bash
cd terraform
terraform destroy
```

El bootstrap se conserva porque contiene el S3 State. Si el laboratorio ya no se utilizará, puedes eliminar posteriormente ese bucket y el Role del bootstrap.

## 11. Estructura

```text
eks-terraform-github-actions/
├── README.md
├── bootstrap/
│   ├── versions.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── terraform/
│   ├── versions.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── terraform.tfvars.example
│   ├── vpc.tf
│   ├── eks.tf
│   ├── kubernetes.tf
│   ├── iam-alb-controller.tf
│   ├── alb-controller-policy.json
│   └── outputs.tf
├── k8s/namespace-tech-store.yaml
└── .github/workflows/terraform.yml
```

## 12. Secuencia didáctica sugerida

1. Explicar IaC y Terraform.
2. Explicar VPC y EKS.
3. Ejecutar bootstrap.
4. Explicar S3 State.
5. Explicar GitHub OIDC.
6. Revisar `terraform plan`.
7. Hacer push y observar Actions.
8. Validar con `kubectl`.
9. Explicar OIDC/IRSA.
10. Explicar ALB Controller y continuar con los labs de Kubernetes.

> La política del AWS Load Balancer Controller se obtiene durante `terraform apply` desde la versión oficial v2.14.1 indicada en el material de clase.
