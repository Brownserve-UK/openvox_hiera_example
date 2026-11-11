# Class: example_module::windows
#
# @summary
#   This class demonstrates how to create a class specific to Windows operating systems.
class example_module::windows {
  # We require the example_module::params class so we can access the parameters
  require example_module::params
  # We require the example_module::base class so we can ensure the directory is created
  require example_module::base

  if $facts['kernel'] != 'windows' {
    fail('This class is only intended for Windows operating systems')
  }

  # Create a file specific to Windows operating systems
  file { "${example_module::params::base_directory}/windows.txt":
    ensure  => 'file',
    content => 'Hello, this file is specific to Windows!',
  }
}
