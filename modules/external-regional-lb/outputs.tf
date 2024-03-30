
output "load_balancer" {
  description = "The load balancer resource"
  value = {
    name       = google_compute_region_url_map.load_balancer.name
    ip_address = google_compute_address.load_balancer.address
  }
}
