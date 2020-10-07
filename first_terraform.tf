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
    name    = "abcd.redirect.com"
    comment = "Redirect Chase Terraform demo"
  }

  backend {
    address = "151.101.2.133"
    name    = "d.sni.global.fastly.net"
    port    = 443
  }

 snippet {
   name     = "Change_jpg_ttl"
   type     = "fetch"
   priority = 8
   content = "if ( req.url ~ \"\\.(jpeg|jpg|gif)$\" ) {\n # jpeg/gif TTL\n set beresp.ttl = 172800s;\n }\n set beresp.http.Cache-Control = \"max-age=\" beresp.ttl;"
}

snippet {
   name     = "Override_host"
   type     = "recv"
   priority = 8
   content = "set req.http.host = \"deciduous-impossible-expansion.glitch.me\";"
 }

  force_destroy = true
}

