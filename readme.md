AWS Microservice Infrastructure with Terraform — V2

Despliegue de un microservicio Spring Boot sobre AWS, completamente definido mediante Terraform, con autoescalado, base de datos RDS, Docker y un pipeline de CI/CD basado en GitHub Actions.

Este proyecto nació como un reto personal para llevar a la práctica conocimientos de AWS más allá de la teoría. La primera versión estaba centrada principalmente en la construcción de la infraestructura; en esta V2 se incorpora Docker y automatización del proceso de build y publicación de la aplicación.

El objetivo final es cubrir el ciclo completo:

Commit → GitHub Actions → Docker build → Amazon ECR → EC2/Auto Scaling → aplicación desplegada

🚀 Arquitectura

La infraestructura utiliza los siguientes servicios de AWS:

VPC para aislar la infraestructura de red.
Subnets públicas y privadas distribuidas entre Availability Zones.
Application Load Balancer (ALB) para recibir y distribuir el tráfico.
EC2 + Auto Scaling Group para ejecutar el microservicio.
Launch Template para definir la configuración de las instancias.
Amazon RDS PostgreSQL como base de datos.
Amazon ECR como registry de imágenes Docker.
IAM Instance Profile para proporcionar permisos a las instancias EC2.
GitHub Actions para automatizar CI/CD.
Terraform para definir toda la infraestructura como código.
Docker para empaquetar y ejecutar la aplicación.
Diagrama lógico
                         ┌────────────────────┐
                         │     Developer      │
                         └─────────┬──────────┘
                                   │
                                git push
                                   │
                                   ▼
                         ┌────────────────────┐
                         │   GitHub Actions   │
                         │                    │
                         │  Build + Test      │
                         │  Docker Build      │
                         │  Push to ECR       │
                         └─────────┬──────────┘
                                   │
                                   ▼
                         ┌────────────────────┐
                         │   Amazon ECR       │
                         │                    │
                         │  Docker Image      │
                         └─────────┬──────────┘
                                   │
                             docker pull
                                   │
                                   ▼
        ┌─────────────────────────────────────────────────────┐
        │                         AWS VPC                     │
        │                                                     │
        │  ┌───────────────────────────────────────────────┐  │
        │  │              Public Subnets                   │  │
        │  │                                               │  │
        │  │       ┌─────────────────────────┐             │  │
        │  │       │ Application Load        │             │  │
        │  │       │ Balancer               │             │  │
        │  │       └────────────┬────────────┘             │  │
        │  │                    │                          │  │
        │  │                    ▼                          │  │
        │  │       ┌─────────────────────────┐             │  │
        │  │       │ Auto Scaling Group      │             │  │
        │  │       │                         │             │  │
        │  │       │  ┌───────┐  ┌───────┐ │             │  │
        │  │       │  │ EC2   │  │ EC2   │ │             │  │
        │  │       │  │Docker │  │Docker │ │             │  │
        │  │       │  └───────┘  └───────┘ │             │  │
        │  │       └────────────┬────────────┘             │  │
        │  └────────────────────┼──────────────────────────┘  │
        │                       │                             │
        │                       │ PostgreSQL                  │
        │                       ▼                             │
        │  ┌───────────────────────────────────────────────┐  │
        │  │               Private Subnets                 │  │
        │  │                                               │  │
        │  │             ┌─────────────────┐               │  │
        │  │             │   RDS PostgreSQL │               │  │
        │  │             └─────────────────┘               │  │
        │  └───────────────────────────────────────────────┘  │
        │                                                     │
        └─────────────────────────────────────────────────────┘

Nota: actualmente el Auto Scaling Group está configurado con min_size = 1, desired_capacity = 1 y max_size = 1. La política de Target Tracking queda preparada para el autoescalado, pero para que pueda aumentar el número de instancias será necesario incrementar max_size.

📦 V2 — ¿Qué ha cambiado?

La V1 se centraba en desplegar la aplicación directamente sobre EC2 y gestionar la infraestructura mediante Terraform.

En esta segunda versión se ha evolucionado el proceso de despliegue:

V1
Terraform
   │
   ├── VPC
   ├── EC2
   ├── RDS
   ├── Auto Scaling
   └── Application
         │
         └── Instalación/configuración en EC2
V2
GitHub
   │
   │ commit
   ▼
GitHub Actions
   │
   ├── Test
   ├── Docker Build
   └── Push
         │
         ▼
       ECR
         │
         │ docker pull
         ▼
   EC2 / Auto Scaling
         │
         ▼
   Docker Container
         │
         ▼
   Spring Boot
         │
         ▼
   RDS PostgreSQL

El cambio principal consiste en separar claramente:

Build de la aplicación
Distribución del artefacto
Infraestructura
Ejecución de la aplicación

Esto evita tener que generar una nueva AMI cada vez que cambia la aplicación.

🐳 Docker

La aplicación Spring Boot se empaqueta como una imagen Docker.

Esto permite que la misma imagen que se construye durante el pipeline sea posteriormente utilizada por las instancias EC2.

El flujo es:

Spring Boot
     │
     ▼
Docker build
     │
     ▼
Docker Image
     │
     ▼
Amazon ECR
     │
     ▼
EC2
     │
     └── docker pull
             │
             ▼
        Docker Container

De esta manera, la AMI utilizada por EC2 únicamente necesita contener el sistema operativo y las herramientas necesarias para ejecutar el contenedor.

La aplicación deja de estar acoplada a la imagen de la máquina.

🔄 CI/CD con GitHub Actions

El pipeline automatiza la construcción y publicación de la aplicación.

De forma conceptual:

                    git push
                       │
                       ▼
              ┌─────────────────┐
              │ GitHub Actions   │
              └────────┬────────┘
                       │
                 Build / Test
                       │
                       ▼
                Docker Build
                       │
                       ▼
                 Docker Image
                       │
                       ▼
                 Amazon ECR

El objetivo es que un cambio en el código pueda convertirse automáticamente en una nueva imagen disponible para el entorno AWS.

Esto elimina pasos manuales del proceso de despliegue y hace que el pipeline sea reproducible.

🏗️ Terraform

Toda la infraestructura se define como código utilizando Terraform.

Entre los principales recursos definidos se encuentran:

Networking
VPC
Public Subnets
Private Subnets
Availability Zones
Security Groups
Compute
EC2 Launch Template
Auto Scaling Group
Auto Scaling Policy
IAM Instance Profile
Load Balancing
Application Load Balancer
Listener
Target Group
Health Checks
Database
RDS PostgreSQL
RDS Subnet Group
Container Registry
Amazon ECR (utilizado por el pipeline para almacenar las imágenes)
🌐 Networking

La VPC utiliza el rango:

10.0.0.0/16

Se han definido subnets públicas y privadas:

Public:
10.0.101.0/24
10.0.102.0/24

Private:
10.0.1.0/24
10.0.2.0/24

El diseño separa los componentes que necesitan exposición pública de aquellos que no deberían estar directamente accesibles desde Internet.

La base de datos RDS se encuentra en las subnets privadas y no es públicamente accesible:

publicly_accessible = false
🔐 Security Groups

Se utilizan diferentes Security Groups para controlar la comunicación entre componentes.

EC2

Permite:

SSH (22)
HTTP de la aplicación (8021)
Tráfico de salida
ALB

Permite recibir tráfico en:

8021

y reenviarlo hacia las instancias EC2.

RDS

PostgreSQL escucha en:

5432

pero el acceso está restringido al Security Group de EC2:

referenced_security_group_id = aws_security_group.ec2.id

Por tanto, conceptualmente:

Internet
   │
   ▼
  ALB
   │
   ▼
 EC2
   │
   ▼
 RDS

La base de datos no necesita aceptar conexiones directamente desde Internet.

❤️ Health Checks

El Application Load Balancer utiliza el endpoint:

/actuator/health

para comprobar el estado de la aplicación.

health_check {
  path    = "/actuator/health"
  matcher = "200"
  port    = 8021
}

Esto permite que el ALB determine si una instancia está preparada para recibir tráfico.

📈 Auto Scaling

Las instancias se gestionan mediante un Auto Scaling Group.

Actualmente:

min_size         = 1
desired_capacity = 1
max_size         = 1

La política utiliza:

ASGAverageCPUUtilization

con un objetivo del:

2%

La infraestructura está preparada para modificar max_size y permitir que el ASG cree nuevas instancias según la métrica configurada.

🗄️ RDS PostgreSQL

La aplicación utiliza PostgreSQL gestionado mediante Amazon RDS.

Configuración actual:

Engine: PostgreSQL
Instance: db.t3.micro
Storage: 10 GB
Port: 5432
Public access: Disabled

Terraform obtiene la versión preferida mediante:

data "aws_rds_engine_version" "test" {
  engine             = "postgres"
  preferred_versions = ["17.6"]
}

La instancia RDS se encuentra asociada a un DB Subnet Group compuesto por las subnets privadas.

⚙️ Configuración mediante user_data

Una de las partes importantes de la V2 es la utilización del user_data del Launch Template.

Terraform genera dinámicamente el script de inicialización:

user_data = base64encode(templatefile("init_script.sh", {
  db_host   = aws_db_instance.default.address
  db_name   = aws_db_instance.default.db_name
  db_user   = aws_db_instance.default.username
  db_pass   = aws_db_instance.default.password
  account_id = data.aws_caller_identity.current.account_id
}))

Esto permite proporcionar a la instancia información necesaria para arrancar el contenedor.

El flujo es:

Terraform
   │
   ▼
Launch Template
   │
   ▼
user_data
   │
   ▼
EC2 initialization
   │
   ▼
Docker
   │
   ▼
Spring Boot Container
🔑 IAM y Amazon ECR

Las instancias EC2 utilizan un IAM Instance Profile.

El objetivo es permitir que la instancia pueda interactuar con los servicios AWS necesarios sin tener que almacenar credenciales estáticas dentro de la máquina.

En particular, la instancia necesita permisos para autenticarse contra ECR y realizar el pull de la imagen.

🧠 Principales aprendizajes

Este proyecto empezó como un ejercicio para aplicar conceptos de AWS y terminó siendo especialmente útil por los problemas que aparecieron durante la implementación.

Algunos de los aprendizajes más importantes fueron:

1. La teoría no siempre refleja el comportamiento real

Durante la V1, la aplicación se reiniciaba constantemente en EC2 y los logs de la aplicación no mostraban un error evidente.

El problema estaba relacionado con la memoria disponible en una instancia t2.micro.

El sistema operativo terminaba el proceso antes de que la aplicación pudiera arrancar correctamente.

Esto fue especialmente interesante porque el problema no estaba realmente en Spring Boot, sino en los recursos disponibles en la infraestructura.

2. El ciclo de vida de una aplicación es importante

Otro problema encontrado fue que las instancias tardaban varios minutos en apagarse correctamente.

La solución pasó por integrar la aplicación con systemd, permitiendo que Linux gestionase correctamente el ciclo de vida del servicio.

Esto ayudó a entender mejor la relación entre:

EC2
 │
 ├── Linux
 │
 ├── systemd
 │
 └── Application
3. Docker simplifica la separación entre infraestructura y aplicación

La V2 elimina la necesidad de crear una nueva AMI cada vez que cambia el código de la aplicación.

Ahora:

AMI
 │
 └── Sistema operativo + dependencias necesarias

mientras que:

Docker Image
 │
 └── Aplicación + runtime

Esto permite mantener más desacoplados el ciclo de vida de la infraestructura y el de la aplicación.

4. CI/CD convierte el proceso en reproducible

El pipeline permite pasar de:

Cambio de código
      ↓
Build manual
      ↓
Copiar aplicación
      ↓
Configurar EC2

a:

Git push
   ↓
GitHub Actions
   ↓
Docker build
   ↓
ECR
   ↓
Infraestructura AWS

La infraestructura deja de depender tanto de pasos manuales.

📁 Estructura del proyecto

Una estructura posible del proyecto es:

.
├── .github/
│   └── workflows/
│       └── ...
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── init_script.sh
│   └── ...
│
├── src/
│   └── ...
│
├── Dockerfile
├── pom.xml
└── README.md

La estructura exacta puede variar dependiendo de la organización utilizada en el repositorio.

🚀 Despliegue
Requisitos

Para desplegar el proyecto es necesario disponer de:

AWS CLI
Terraform
Docker
Java / Maven
Una cuenta de AWS
Una clave SSH para EC2
Un repositorio de GitHub con GitHub Actions habilitado
1. Configurar AWS

Configurar las credenciales de AWS mediante el mecanismo habitual de AWS CLI.

Comprobar que las credenciales funcionan:

aws sts get-caller-identity
2. Configurar variables de Terraform

Crear el fichero correspondiente con las variables necesarias.

Por ejemplo:

aws_region     = "us-east-1"
instance_type  = "..."
local_ip_range = "..."

Los valores concretos dependerán del entorno donde se quiera desplegar.

3. Inicializar Terraform
terraform init
4. Revisar el plan
terraform plan

Revisar cuidadosamente los recursos que Terraform propone crear.

5. Aplicar la infraestructura
terraform apply

Terraform creará los recursos necesarios en AWS.

🧹 Destruir la infraestructura

Para eliminar los recursos creados:

terraform destroy

Importante: el código actual utiliza skip_final_snapshot = true para RDS, por lo que destruir la infraestructura puede eliminar la instancia de base de datos sin conservar un snapshot final.

🔒 Consideraciones de seguridad

Este proyecto es principalmente un entorno de aprendizaje y todavía tiene varios puntos que mejoraría antes de considerarlo una arquitectura preparada para producción.

Por ejemplo, las credenciales de RDS no deberían mantenerse directamente en el código Terraform, como ocurre actualmente con:

password = "arcoiris8"

Una evolución natural sería utilizar:

AWS Secrets Manager
SSM Parameter Store
IAM Roles
GitHub OIDC
Rotación de credenciales
HTTPS/TLS en el ALB
Security Groups más restrictivos
Subnets privadas para las instancias de aplicación
NAT Gateway o endpoints VPC cuando sean necesarios
ECR con políticas adecuadas
Tags y políticas de ciclo de vida de imágenes

Estas mejoras quedan fuera del alcance de esta versión, pero forman parte del siguiente paso lógico del proyecto.

🔮 Próximos pasos

Algunas mejoras que podrían incorporarse en futuras versiones:

 HTTPS mediante ACM
 Route 53 + dominio propio
 AWS Secrets Manager para credenciales
 GitHub Actions mediante OIDC en lugar de credenciales estáticas
 Auto Scaling real con max_size > 1
 Migrar EC2 a subnets privadas
 NAT Gateway / VPC Endpoints según necesidades
 ECR lifecycle policies
 CloudWatch Logs y métricas
 Alertas mediante CloudWatch
 Blue/Green o Rolling Deployments
 Versionado/tagging de imágenes Docker
 Separación de entornos dev / staging / prod
 Modularización adicional de Terraform
 Gestión remota del Terraform State mediante S3 + locking
🎯 Objetivo del proyecto

Más allá de crear una infraestructura funcional, el objetivo principal ha sido entender qué ocurre realmente cuando una aplicación pasa de ejecutarse localmente a ejecutarse en la nube.

La V1 permitió aprender sobre:

VPC
EC2
RDS
Networking
Security Groups
IAM
Auto Scaling
Load Balancing
Terraform

La V2 añade:

Docker
ECR
GitHub Actions
CI/CD
Containerization

El resultado es una arquitectura donde el proceso completo queda automatizado y definido como código:

                    ┌──────────────┐
                    │   Developer  │
                    └──────┬───────┘
                           │
                        git push
                           │
                           ▼
                    ┌──────────────┐
                    │    GitHub    │
                    │   Actions    │
                    └──────┬───────┘
                           │
                      Docker Build
                           │
                           ▼
                    ┌──────────────┐
                    │     ECR      │
                    └──────┬───────┘
                           │
                       docker pull
                           │
                           ▼
                    ┌──────────────┐
                    │     EC2      │
                    │  AutoScaling │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ Spring Boot  │
                    │   Docker     │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ RDS Postgres │
                    └──────────────┘

El objetivo de esta V2 no es únicamente desplegar una aplicación, sino construir un pipeline reproducible que conecte desarrollo, build, distribución y ejecución sobre una infraestructura AWS definida completamente mediante código.
