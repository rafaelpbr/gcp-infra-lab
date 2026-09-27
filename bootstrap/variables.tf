variable "project_id" {
  description = "ID del proyecto de GCP donde se crea el bootstrap."
  type        = string
}

variable "region" {
  description = "Región por defecto para los recursos regionales (p. ej. el bucket de state)."
  type        = string
  default     = "us-central1"
}

variable "github_owner" {
  description = "Usuario u organización de GitHub dueño del repositorio."
  type        = string
}

variable "github_repo" {
  description = "Nombre del repositorio de GitHub (sin el owner)."
  type        = string
}

variable "github_owner_id" {
  description = "ID numérico inmutable del owner en GitHub. Se usa en la condición de WIF porque, a diferencia del nombre, no se puede reutilizar si la cuenta se renombra o elimina."
  type        = string
}

variable "github_repo_id" {
  description = "ID numérico inmutable del repositorio en GitHub. Forma parte del claim sub en formato inmutable, que se usa en el binding de tf-apply."
  type        = string
}
