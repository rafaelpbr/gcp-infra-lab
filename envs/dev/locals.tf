# Valores de este entorno. Van en locals (y no en terraform.tfvars) porque
# *.tfvars está en .gitignore: el pipeline de GitHub Actions no los tendría.
# Ninguno de estos valores es secreto, así que es seguro versionarlos.
locals {
  project_id  = "gcp-infra-lab-509812"
  region      = "us-central1"
  environment = "dev"

  # Labels comunes: se aplican a todos los recursos vía default_labels del
  # provider. Sirven para filtrar costos y saber quién gestiona cada recurso.
  labels = {
    environment = local.environment
    managed_by  = "terraform"
    repo        = "gcp-infra-lab"
  }
}
