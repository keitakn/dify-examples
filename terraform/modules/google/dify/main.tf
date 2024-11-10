resource "google_artifact_registry_repository" "dify_repo" {
  location      = var.region
  repository_id = "${var.env}-dify-repo"
  description   = "Artifact Registry for Dify"
  format        = "DOCKER"
}