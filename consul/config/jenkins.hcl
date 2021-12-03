
# Write test data
# Set the path to "secret/data/mysql/*" if you are running `kv-v2`
path "kv/jenkins/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}
path "auth/approle/login" { 
  capabilities = [ "create", "read" ] 
}

path "sys/auth/approle/*" {
  capabilities = [ "create", "read", "update", "delete", "sudo" ]
}
path "sys/policies/acl/*" {
  capabilities = [ "read", "update", "list" ]
}
path "/auth/token/create" {
  capabilities = ["update"]
}
path "auth/approle/role/jenkins/secret-id" {
  capabilities = ["read","create","update"]
}