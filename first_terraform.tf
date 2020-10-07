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
    address = "run.mocky.io"
    name    = "From fiddle b15757c0"
    port    = 443
  }

 snippet {
   name     = "Force clustering"
   type     = "recv"
   priority = 8
   content = "if (req.restarts == 0) {	\n unset req.http.redirectchase_restart; \n } \n # If restarting for a redirect, re-enable clustering \n if (req.http.redirectchase_restart) { \n set req.http.Fastly-Force-Shield = \"1\"; \n }"
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
   content = " # Tag the response so that we can track whether it came from a\n # customer origin (and not a Fastly shield POP) \n set beresp.http.redirectchase_isorigin = req.backend.is_origin;
}

snippet {
  name	= "Redirect chase"
  type	= "deliver"
  priority = 8
  content = "declare local var.maxRedirects INTEGER;
declare local var.curRedirects INTEGER;
declare local var.redirectPath STRING;
declare local var.redirectHost STRING;

set var.maxRedirects = 2;
set var.curRedirects = std.atoi(if (req.http.redirectchase_restart, req.http.redirectchase_restart, \"0\"));

# Perform an internal redirect if...
if (
  resp.status >= 300 && resp.status < 400 &&            # the response is a redirect
  resp.http.redirectchase_isorigin &&                   # and it came from a customer origin
  var.curRedirects < var.maxRedirects &&                # and we haven't exceeded a maximum number of redirects
  resp.http.location ~ \"^(?:https?://([^/]+))?(/.*)?$\") # and there's a valid location header
{
  set var.redirectHost = re.group.1;
  set var.redirectPath = re.group.2;
  
  # Only do so if the location header does not specify a host, or the host matches the client-side host header, or a whitelist of 'local' domains
  if (var.redirectHost == \"\" || var.redirectHost == req.http.host) {
    set req.url = if (var.redirectPath, var.redirectPath, \"/\");
    set var.curRedirects += 1;
    set req.http.redirectchase_restart = var.curRedirects;
    restart;
  }
}
unset resp.http.redirectchase_isorigin;"
}

  force_destroy = true
}

