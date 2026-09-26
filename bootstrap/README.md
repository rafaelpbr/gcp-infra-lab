# bootstrap/

Aquí va la infraestructura que se aplica **una sola vez, desde tu máquina local**,
con tus propias credenciales (`gcloud auth application-default login`):

- **Bucket GCS para el state remoto** de Terraform (con versionado activado).
- **Workload Identity Pool y Provider** que confían en los tokens OIDC de GitHub Actions,
  restringidos a este repositorio.
- **Service account(s)** que el pipeline suplantará, con los roles mínimos necesarios.

## ¿Por qué aparte? El problema del huevo y la gallina

El pipeline necesita dos cosas para funcionar:

1. Un **bucket** donde guardar el state.
2. Una **identidad (WIF + service account)** para autenticarse en GCP.

Pero ambas son infraestructura… y el pipeline no puede crear aquello que necesita
para poder arrancar. Por eso se crean primero, a mano y desde local, en esta carpeta.

## Notas

- Se ejecuta rara vez: solo al inicio o al cambiar permisos del pipeline.
- Su state puede empezar local y luego migrarse al bucket que él mismo crea
  (`terraform init -migrate-state`).
- Cualquier cambio aquí amplía o reduce lo que el pipeline puede hacer: revisar con cuidado.
