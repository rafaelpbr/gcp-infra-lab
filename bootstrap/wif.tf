locals {
  github_repository = "${var.github_owner}/${var.github_repo}"
}

# Pool: "contenedor" de identidades externas en las que el proyecto confía.
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions"
  description               = "Identidades de GitHub Actions para el pipeline de Terraform"

  depends_on = [google_project_service.apis]
}

# Provider: define CÓMO confiar en los tokens OIDC que emite GitHub.
resource "google_iam_workload_identity_pool_provider" "github" {
  #checkov:skip=CKV_GCP_125:La condición no usa assertion.sub a propósito: filtra por repository_owner_id (inmutable) y repository, y la restricción por job/environment se hace en cada binding IAM (subject inmutable para tf-apply). Un sub fijo aquí impediría que plan y apply compartan el provider.
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  # Traduce los claims del token de GitHub a atributos de Google, que luego
  # se usan en la condición y en los bindings IAM (principal/principalSet).
  attribute_mapping = {
    "google.subject"                = "assertion.sub" # p. ej. repo:rafaelpbr/gcp-infra-lab:environment:dev
    "attribute.repository"          = "assertion.repository"
    "attribute.repository_owner_id" = "assertion.repository_owner_id"
    "attribute.ref"                 = "assertion.ref"
  }

  # Filtro de entrada: rechaza cualquier token que no venga de ESTE repo.
  # Se exige además el owner_id numérico (inmutable) para que nadie pueda
  # "heredar" el acceso recreando una cuenta/repo con el mismo nombre.
  attribute_condition = <<-EOT
    assertion.repository_owner_id == '${var.github_owner_id}' &&
    assertion.repository == '${local.github_repository}'
  EOT
}
