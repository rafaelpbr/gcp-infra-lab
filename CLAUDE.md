# CLAUDE.md

Reglas para agentes de IA que trabajen en este repositorio.

## Contexto

- Laboratorio personal de GitOps: Terraform sobre GCP, ejecutado desde GitHub Actions.
- Proyecto GCP: `gcp-infra-lab-509812`. Región por defecto: `us-central1`.
- El usuario es principiante, trabaja en Windows con PowerShell, y usa Terraform `1.16.2`.
- `bootstrap/` se aplica una sola vez desde local; `envs/dev/` solo lo aplica el pipeline.

## Reglas obligatorias

1. **Nunca crear ni sugerir llaves de service account (JSON keys).** La autenticación es
   exclusivamente vía Workload Identity Federation (WIF), tanto en CI como en cualquier
   ejemplo o documentación. Localmente se usa `gcloud auth application-default login`.
2. **Nunca escribir secretos, tokens ni IDs de billing en el código**, ni en `.tf`, ni en
   `.tfvars.example`, ni en workflows, ni en documentación. Usar variables, GitHub
   Secrets/Variables o Secret Manager.
3. **Nunca ejecutar `terraform apply` ni `terraform destroy` sin pedir confirmación
   explícita al usuario**, cada vez. Una aprobación anterior no cuenta para la siguiente.
4. **Mínimo privilegio en todo rol IAM.** Preferir roles predefinidos específicos sobre
   roles básicos (`roles/owner`, `roles/editor`) y bindings a nivel de recurso sobre nivel
   de proyecto. Justificar cada rol con un comentario junto al binding.
5. **Fijar todas las versiones**: `required_version` de Terraform y `version` de cada
   provider y módulo. Versionar `.terraform.lock.hcl`.
6. **Explicar en español** cada archivo que se cree o modifique: qué hace y por qué.
