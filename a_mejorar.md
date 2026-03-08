- Refactorizar terraform para tenerlo ordenado en modulos
- Usar AWS Identity Cetner para conectar con terraform
- Revisar otras formas de conectar a las ec2 que no sean poner el nombre de las access_keys en terraform
- Leer el jar de algun sitio mejor que un S3 si lo hay
- Subir el jar a s3 por consola
- Implemetnar CI/CD para terraform
- Implementar CI/CD para el jar
- Separar terraform en bootstrap y runtime, para tener infraestructura que siempre esté creada
- Unificar las variables.tf en un solo archivo
- Usar state lock para terraform state
- Sacar credenciales a Secret Manager o Terraform de alguna forma

Hecho:
- Conectar el jar a una bbdd