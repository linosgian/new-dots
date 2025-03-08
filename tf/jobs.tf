resource "nomad_job" "jobs" {
  for_each = { for f in fileset("${path.module}/jobs", "*.hcl") : trimsuffix(f, ".hcl") => f }
  # for_each = fileset("${path.module}/jobs", "*.hcl")
  jobspec = templatefile("${path.module}/jobs/${each.value}", {
    path = path.module
  })
}
