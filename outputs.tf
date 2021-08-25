output "manager_id" {
  value       = google_compute_region_instance_group_manager.grp.id
  description = "Identifier for the instance group manager"
}

output "manager_self_link" {
  value       = google_compute_region_instance_group_manager.grp.self_link
  description = "The URL for the instance group manager"
}

output "instance_group_url" {
  value       = google_compute_region_instance_group_manager.grp.instance_group
  description = "The full URL of the instance group created by the manager"
}
