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
| `.github/workflows/`   | Workflow `terraform-dev`: `plan` + `checkov` en cada PR, `apply` tras merge a `main`.          |
| `.github/dependabot.yml` | Actualizaciones semanales de actions y del provider de Terraform.                          |
| `.github/CODEOWNERS`   | Dueños del código cuya revisión se pide en los PRs.                                            |
| `.gitignore`           | Evita versionar state, variables con secretos, llaves y archivos locales.                      |
| `.gitattributes`       | Fuerza finales de línea LF (importante trabajando desde Windows).                              |
| `CLAUDE.md`            | Reglas para agentes de IA que trabajen en este repo.                                           |

## Configuración fuera del código

Parte de la seguridad del pipeline no vive en Terraform sino en la configuración
de GitHub. Si se pierde (p. ej. al recrear el repo), hay que rehacerla a mano.

### 1. Variables del repositorio

*Settings → Secrets and variables → Actions → Variables → Repository variables*.
No son secretos (WIF no usa credenciales guardadas); los valores salen de
`terraform output` en `bootstrap/`.

| Variable           | Valor (output de bootstrap)                                                                 |
|--------------------|---------------------------------------------------------------------------------------------|
| `GCP_WIF_PROVIDER` | `wif_provider_name` → `projects/<NÚMERO>/locations/global/workloadIdentityPools/github-pool/providers/github-provider` |
| `GCP_PLAN_SA`      | `tf_plan_service_account_email`                                                             |

### 2. Environment `dev`

*Settings → Environments → dev*. Es la puerta del job `apply`:

- **Required reviewers**: `@rafaelpbr`. Cada apply espera una aprobación manual.
- **Deployment branches and tags**: *Selected branches* → solo `main`. Impide que un
  job lanzado desde un PR u otra rama use el environment (y, por tanto, obtenga el
  subject OIDC que acepta `tf-apply`).
- **Environment variable** `GCP_APPLY_SA` = `tf_apply_service_account_email`. Al
  definirla solo en el environment, únicamente los jobs que pasan por `dev` la ven.

### 3. Subject OIDC inmutable

El repo usa el formato inmutable del claim `sub`
(`use_immutable_subject: true`), que incluye los IDs numéricos del owner y del repo:

```
repo:rafaelpbr@60355588/gcp-infra-lab@1389435239:environment:dev
```

El binding de `tf-apply` en `bootstrap/service_accounts.tf` espera exactamente ese
valor. Comprobar la configuración con:

```
gh api /repos/rafaelpbr/gcp-infra-lab/actions/oidc/customization/sub
```

Si se desactivara, GitHub volvería a emitir `repo:rafaelpbr/gcp-infra-lab:environment:dev`
y el apply fallaría con `403 iam.serviceAccounts.getAccessToken`.

### 4. Ruleset de `main` (paso 7b)

*Settings → Rules → Rulesets*. Se creará en el paso 7b para que `main` solo cambie
mediante PRs verificados:

- Exigir Pull Request antes de hacer merge (sin push directo a `main`).
- **Required status checks**: `plan` y `checkov`. Por eso el trigger `pull_request`
  del workflow no tiene filtro `paths`: un check requerido que no se ejecuta deja el
  PR bloqueado.
- Bloquear force push y borrado de la rama.
- Revisión de code owners (`.github/CODEOWNERS`): ojo, con un único mantenedor
  GitHub no permite aprobar tu propio PR; se decidirá en 7b cómo resolverlo.

## Estado

- `bootstrap/` aplicado desde local (state en GCS, prefix `bootstrap`).
- `envs/dev/` gestionado por el pipeline (state en GCS, prefix `envs/dev`).
