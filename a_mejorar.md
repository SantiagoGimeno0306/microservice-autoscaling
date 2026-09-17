- Refactorizar terraform para tenerlo ordenado en modulos
- Usar AWS Identity Center para conectar con terraform
- Implementar CI/CD para terraform
- Unificar las variables.tf en un solo archivo
- Usar state lock para terraform state
- Sacar credenciales a Secret Manager
- Rolling deployments en ASG

Hecho:
- Conectar el jar a una bbdd
- Separar terraform en bootstrap y runtime, para tener infraestructura que siempre esté creada
- Implementar CI/CD para el jar