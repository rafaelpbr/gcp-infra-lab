locals {
  required_apis = toset([
    "iam.googleapis.com",                  # Service accounts, WIF pools/providers, roles custom
    "iamcredentials.googleapis.com",       # Emitir tokens de corta duración al suplantar una SA
    "sts.googleapis.com",                  # Intercambiar el token OIDC de GitHub por uno de Google
    "storage.googleapis.com",              # Bucket de state y buckets de envs/dev
    "cloudresourcemanager.googleapis.com", # Leer/modificar la política IAM del proyecto
    "serviceusage.googleapis.com",         # Habilitar/consultar las propias APIs
  ])
}

resource "google_project_service" "apis" {
  for_each = local.required_apis

  project = var.project_id
  service = each.value

  # Si algún día se destruye el bootstrap, NO deshabilitar las APIs: otros
  # recursos del proyecto podrían depender de ellas y romperse.
  disable_on_destroy = false
}
