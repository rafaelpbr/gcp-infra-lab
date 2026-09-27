# Sin credenciales en el código: en GitHub Actions las aporta WIF
# (google-github-actions/auth); en local, `gcloud auth application-default login`.
provider "google" {
  project = local.project_id
  region  = local.region

  # Se añaden automáticamente a todo recurso que soporte labels.
  default_labels = local.labels
}
