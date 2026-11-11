# Class: example_module::linux
#
# @summary
#   This class shows an example of a class that is specific to Linux operating systems.
class example_module::linux {
  # require the example_module::params class so we can access the parameters
  require example_module::params
  # require the example_module::base class so we can ensure the directory is created
  require example_module::base

  if $facts['kernel'] != 'Linux' {
    fail('This class is only intended for Linux operating systems')
  }

  # Create a file specific to Linux operating systems
  file { "${example_module::params::base_directory}/linux":
    ensure  => 'file',
    content => 'Hello, this file is specific to Linux!',
  }
}
