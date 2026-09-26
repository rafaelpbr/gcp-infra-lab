# gcp-infra-lab

Laboratorio personal para aprender **GitOps de infraestructura**: gestionar Google Cloud
con **Terraform**, ejecutado desde **GitHub Actions**, autenticando con
**Workload Identity Federation (WIF)**, es decir, **sin llaves JSON de service account**.

| Dato               | Valor                  |
|--------------------|------------------------|
| Proyecto GCP       | `gcp-infra-lab-509812` |
| Región por defecto | `us-central1`          |
| Terraform          | `1.16.2` (fijado)      |

## Flujo GitOps

Git es la única fuente de verdad: los cambios de infraestructura entran por Pull Request
y solo el pipeline los aplica.

```
  Tú (rama feature)
        │
        │  git push + abrir Pull Request
        ▼
┌──────────────────┐     GitHub Actions obtiene un token OIDC de corta duración
│  Pull Request    │     y lo cambia por credenciales de GCP vía WIF (sin llaves JSON)
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ terraform plan   │  fmt + validate + plan; el resultado se publica en el PR
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Revisión humana  │  lees el plan: ¿qué se crea, cambia o destruye?
└────────┬─────────┘
         │  aprobado
         ▼
┌──────────────────┐
│ Merge a main     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ terraform apply  │  el pipeline aplica en GCP; el state vive en un bucket GCS
└──────────────────┘
```

## Estructura de carpetas

| Carpeta / archivo      | Propósito                                                                                     |
|------------------------|-----------------------------------------------------------------------------------------------|
| `bootstrap/`           | Lo que se aplica **una sola vez desde local**: bucket de state, WIF, service accounts.        |
| `envs/dev/`            | Infraestructura del entorno `dev`, gestionada **solo por el pipeline**.                       |
| `.github/workflows/`   | Workflows de GitHub Actions (plan en PR, apply en merge). Aún vacío.                          |
| `.gitignore`           | Evita versionar state, variables con secretos, llaves y archivos locales.                      |
| `.gitattributes`       | Fuerza finales de línea LF (importante trabajando desde Windows).                              |
| `CLAUDE.md`            | Reglas para agentes de IA que trabajen en este repo.                                           |

## Estado

Solo esqueleto. Todavía no hay recursos de Terraform ni workflows.
