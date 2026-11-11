# @summary
#   Defined type for an r10k source
type Openvox_server::R10k_source = Struct[{
  source_name => String,
  remote_path => String,
}]
