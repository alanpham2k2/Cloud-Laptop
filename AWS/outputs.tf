output "public_ip" {
  description = "Public IP address of the Spot Instance"
  value       = try(data.aws_instances.cloud_laptop_live.public_ips[0], "Run 'terraform refresh' in 30s")
}

output "instance_type" {
  description = "The actual instance type AWS selected (e.g. t4g.small)"
  # If the data source didn't run (count=0), return a placeholder message
  value       = try(data.aws_instance.cloud_laptop_details[0].instance_type, "Waiting for instance...")
}
