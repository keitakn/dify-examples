module "dify" {
  source = "../../../../../modules/google/dify"
  env    = local.env
  region = local.region
}
