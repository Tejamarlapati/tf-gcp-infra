output "instance_name" {
  value = google_sql_database_instance.database_instance.name
}

output "ip_address" {
  value = google_sql_database_instance.database_instance.private_ip_address
}

output "username" {
  value = google_sql_user.database_user.name
}

output "password" {
  value = random_password.database_password.result
}

output "database_name" {
  value = google_sql_database.database.name
}
