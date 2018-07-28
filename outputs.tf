output "repositories" {
  value = "${merge(var.definition_vars, zipmap(keys(var.repositories), aws_ecr_repository.this.*.repository_url))}"
}

output "role" {
  value = "${aws_iam_role.this.name}"
}

output "role_arn" {
  value = "${aws_iam_role.this.arn}"
}