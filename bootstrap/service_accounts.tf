# =============================================================================
# tf-plan: solo lectura. La usan los jobs de Pull Request (terraform plan).
# =============================================================================
resource "google_service_account" "tf_plan" {
  project      = var.project_id
  account_id   = "tf-plan"
  display_name = "Terraform plan (solo lectura)"
  description  = "Usada por GitHub Actions para terraform plan en Pull Requests"

  depends_on = [google_project_service.apis]
}

# Rol custom con SOLO los permisos que necesita `terraform plan` para
# refrescar los recursos de envs/dev (buckets y sus políticas IAM).
# No existe un rol predefinido de solo lectura que incluya getIamPolicy:
# roles/storage.bucketViewer no lo trae, y roles/viewer o
# roles/iam.securityReviewer otorgan lectura sobre muchísimo más.
resource "google_project_iam_custom_role" "tf_plan_storage_reader" {
  project     = var.project_id
  role_id     = "tfPlanStorageReader"
  title       = "Terraform plan - lector de buckets"
  description = "Lectura de metadatos y política IAM de buckets para terraform plan"
  permissions = [
    "storage.buckets.get",          # Leer configuración de cada bucket
    "storage.buckets.list",         # Listar buckets del proyecto
    "storage.buckets.getIamPolicy", # Leer los bindings IAM de cada bucket
  ]

  depends_on = [google_project_service.apis]
}

# Justificación: permite a plan leer el estado real de los buckets de
# envs/dev y compararlo con el código. Sin permisos de escritura.
resource "google_project_iam_member" "tf_plan_storage_reader" {
  project = var.project_id
  role    = google_project_iam_custom_role.tf_plan_storage_reader.id
  member  = "serviceAccount:${google_service_account.tf_plan.email}"
}

# Justificación: plan necesita LEER el state (objetos) del bucket de state,
# y solo de ese bucket.
#
# Trade-off de -lock=false: el backend GCS bloquea creando un objeto .tflock,
# lo que exigiría permiso de escritura (objectCreator/objectAdmin). Para que
# tf-plan sea estrictamente de solo lectura, el plan corre con -lock=false.
# Riesgo: si un apply está escribiendo el state al mismo tiempo, el plan puede
# leer un state a medio actualizar y mostrar un resultado desfasado. Es
# aceptable porque el plan es solo informativo: nunca modifica nada y el
# apply (que SÍ bloquea) vuelve a calcular su propio plan antes de aplicar.
resource "google_storage_bucket_iam_member" "tf_plan_state_reader" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.tf_plan.email}"
}

# Justificación: permite que CUALQUIER workflow de este repositorio (ramas,
# PRs) suplante a tf-plan. Es aceptable porque tf-plan solo puede leer.
resource "google_service_account_iam_member" "tf_plan_wif" {
  service_account_id = google_service_account.tf_plan.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${local.github_repository}"
}

# =============================================================================
# tf-apply: escritura. Solo la usan jobs que pasan por el environment "dev".
# =============================================================================
resource "google_service_account" "tf_apply" {
  project      = var.project_id
  account_id   = "tf-apply"
  display_name = "Terraform apply (escritura)"
  description  = "Usada por GitHub Actions para terraform apply tras merge a main"

  depends_on = [google_project_service.apis]
}

# Justificación: envs/dev solo gestionará buckets de GCS (crearlos,
# modificarlos, borrarlos y administrar su IAM). storage.admin es el rol
# predefinido más acotado que cubre todo eso; no da acceso a otros servicios.
resource "google_project_iam_member" "tf_apply_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.tf_apply.email}"
}

# Justificación: leer/escribir el state y crear/borrar el lock (.tflock) en el
# bucket de state. Hoy es redundante con storage.admin a nivel de proyecto,
# pero se declara explícito para que el acceso al state no se pierda si en el
# futuro se reduce el rol de proyecto.
resource "google_storage_bucket_iam_member" "tf_apply_state_admin" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.tf_apply.email}"
}

# Justificación: SOLO el subject exacto del environment "dev" puede suplantar
# a tf-apply. GitHub emite ese subject únicamente para jobs declarados con
# `environment: dev`, que pueden protegerse con reglas (aprobación manual,
# solo rama main). Una rama o un PR cualquiera no obtiene ese subject.
#
# Formato inmutable del claim sub (use_immutable_subject: true en el repo):
#   repo:<owner>@<owner_id>/<repo>@<repo_id>:environment:dev
# Además de los nombres, incluye los IDs numéricos del owner y del repo, que
# GitHub nunca reasigna. Con el formato viejo (repo:<owner>/<repo>:...), si se
# renombrara o borrara la cuenta o el repo, otra persona podría recrear uno con
# el mismo nombre y emitir un subject idéntico. Con los IDs eso es imposible.
resource "google_service_account_iam_member" "tf_apply_wif" {
  service_account_id = google_service_account.tf_apply.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/subject/repo:${var.github_owner}@${var.github_owner_id}/${var.github_repo}@${var.github_repo_id}:environment:dev"
}
