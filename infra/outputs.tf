output "cluster_name" {
  value = module.eks.cluster_name
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "db_username" {
  value = module.rds.username
}

output "db_password" {
  value     = random_password.db_password.result
  sensitive = true
}
