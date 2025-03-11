resource "nomad_job" "jobs" {
  for_each = { for f in fileset("${path.module}/jobs", "*.hcl") : trimsuffix(f, ".hcl") => f }
  jobspec = templatefile("${path.module}/jobs/${each.value}", merge(
  {
    path = path.module
  },
  nonsensitive(data.sops_file.secrets.data)
))
}
