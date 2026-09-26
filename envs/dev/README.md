# envs/dev/

Aquí va la infraestructura del entorno **dev**, gestionada **solo por el pipeline**
de GitHub Actions:

- En cada **Pull Request** se ejecuta `terraform plan` y el resultado se muestra para revisión.
- Tras el **merge a `main`** se ejecuta `terraform apply`.

## Reglas

- No hacer `terraform apply` desde local: todo cambio entra por Pull Request.
- El state vive en el bucket GCS creado en [`../../bootstrap/`](../../bootstrap/).
- La autenticación es vía Workload Identity Federation; no hay llaves JSON.
- Los valores por entorno van en `*.tfvars` (ignorados por Git); se versiona solo
  `terraform.tfvars.example` como plantilla.
