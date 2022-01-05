output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

# TODO: Put all outputs