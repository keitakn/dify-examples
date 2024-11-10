terraform {
  backend "gcs" {
    bucket = "dev-dify-examples-tfstate"
    prefix = "10-dify/tfstate"
  }
}
