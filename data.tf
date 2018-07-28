data "template_file" "this" {
    template = "${file(var.definition_file)}"
    vars = "${merge(var.definition_vars, zipmap(keys(var.repositories), aws_ecr_repository.this.*.repository_url), map("log_group", "${module.logs.name}"))}"
}




