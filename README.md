# GitOps EKS + Argo CD

Terraform para desplegar en AWS: VPC, EKS, Argo CD y una aplicación de muestra sincronizada desde este mismo repositorio.

## Prerrequisitos
- AWS SSO iniciado: `aws sso login --profile vop-dev`
- Terraform >= 1.5
- kubectl y awscli configurados con el perfil `vop-dev`
- Conectividad a la VPC (VPN/Direct Connect/bastión) para acceder al endpoint privado del clúster y a servicios internos (Argo CD).

## Estructura
- `main.tf`, `vpc.tf`, `eks.tf`, `argo.tf`, `variables.tf`, `outputs.tf`: Infraestructura y Argo CD.
- `apps/sample-app/`: Manifiestos que Argo CD sincroniza al clúster.

## Despliegue
1) Autenticarse: `aws sso login --profile vop-dev`
2) Inicializar: `terraform init`
3) Revisar infraestructura (solo VPC + EKS por defecto): `terraform plan`
4) Aplicar infraestructura: `terraform apply`
5) Generar kubeconfig local (desde una red dentro de la VPC):  
   `aws eks update-kubeconfig --name gitops-eks --region us-east-1 --profile vop-dev`
6) Instalar Argo CD + app de ejemplo (requiere conectividad privada al clúster):  
   `terraform plan  -var enable_argocd_bootstrap=true`  
   `terraform apply -var enable_argocd_bootstrap=true`

## Acceso al clúster
Configurar kubeconfig después de aplicar:
```bash
aws eks update-kubeconfig \
  --name gitops-eks \
  --region us-east-1 \
  --profile vop-dev
```

## Argo CD
- Esperar el LoadBalancer interno y obtener el endpoint (accesible solo desde la VPC):
```bash
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```
- Usuario: `admin`
- Password inicial:
```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d; echo
```

## Flujo GitOps
- Argo CD observa `https://github.com/juankamilo812/gitops-eks-argocd.git`, rama `main`, ruta `apps/sample-app`.
- Cualquier commit a esa ruta se sincroniza automáticamente (prune + selfHeal).

## Variables principales
Se pueden ajustar en `terraform.tfvars` o vía `-var`:
- `region` (por defecto `us-east-1`)
- `aws_profile` (por defecto `vop-dev`)
- `cluster_name` (por defecto `gitops-eks`)
- `git_repo_revision` (por defecto `main`)
- CIDRs para VPC y subredes públicas/privadas
- `enable_argocd_bootstrap` (por defecto `false`): instala Argo CD + app de ejemplo cuando se pone en `true`. Mantener en `false` para que `terraform plan` funcione sin kubeconfig en el primer despliegue.
- `admin_cidr` (por defecto `201.233.190.31/32`): único origen permitido para SSH a los nodos.

## Cambios de privacidad y endpoints
- Se usa NAT Gateway (1 por defecto) para permitir salida a Internet desde subredes privadas.
- El endpoint del clúster EKS sigue siendo solo privado. Necesitas conectarte desde la red interna (VPN/Direct Connect/bastión) para `kubectl` o Helm.
- Argo CD expone un LoadBalancer externo pero restringido por `loadBalancerSourceRanges` al `admin_cidr` para UI/API.
- Para limitar la exposición, puedes añadir endpoints VPC si quieres reducir tráfico vía NAT y ajustar egress rules según tus necesidades.
