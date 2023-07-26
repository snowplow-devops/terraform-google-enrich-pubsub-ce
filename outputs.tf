output "manager_id" {
  value       = module.service.manager_id
  description = "Identifier for the instance group manager"
}

output "manager_self_link" {
  value       = module.service.manager_self_link
  description = "The URL for the instance group manager"
}

output "instance_group_url" {
  value       = module.service.instance_group_url
  description = "The full URL of the instance group created by the manager"
}
