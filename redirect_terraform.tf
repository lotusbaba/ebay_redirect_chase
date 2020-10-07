# Configure the Fastly Provider
provider "fastly" {
}

# output varialbles on the console
output "Fastly-Version" {
  value = "fastly_service_v1.redirect_chase_terraform_service.active_version"
}

# Create a Service

resource "fastly_service_v1" "redirect_chase_terraform_service" {
  name = "Redirect Chase Terraform Service"

  domain {
    name    = "abcd-redirect-com.global.ssl.fastly.net"
    comment = "Redirect Chase Terraform demo"
  }

  backend {
    address = "run.mocky.io"
    name    = "From fiddle b15757c0"
    port    = 443
  }

 snippet {
   name     = "Force clustering"
   type     = "recv"
   priority = 8
   content = "if (req.restarts == 0) {	\n unset req.http.redirectchase_restart; \n } \n # If restarting for a redirect, re-enable clustering \n if (req.http.redirectchase_restart) { \n set req.http.Fastly-Force-Shield = \"1\";\n}\n set req.http.host = \"run.mocky.io\"; \n"
}

snippet {
   name     = "Unset_header_miss"
   type     = "miss"
   priority = 8
   content = "unset bereq.http.redirectchase_restart;"
 }

snippet {
   name     = "Unset_header_pass"
   type     = "pass"
   priority = 8
   content = "unset bereq.http.redirectchase_restart;"
 }

snippet	{
   name     = "Track response"
   type     = "fetch"
   priority = 8
   content = "# Tag the response so that we can track whether it came from a\n # customer origin (and not a Fastly shield POP) \n set beresp.http.redirectchase_isorigin = req.backend.is_origin;"
}

  force_destroy = true
}

