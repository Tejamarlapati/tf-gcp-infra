
output "load_balancer" {
  description = "The load balancer resource"
  value = {
    name       = google_compute_url_map.load_balancer.name
    ip_address = local.ip_address
  }
}
