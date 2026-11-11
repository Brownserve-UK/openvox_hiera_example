# Class: example_module::base
#
# @summary
#   This class will create the directory and file defined in the example_module::params class
class example_module::base {
  # We require the example_module::params class so we can access the parameters
  require example_module::params
  # We use the $base_directory parameter to create the directory
  file { $example_module::params::base_directory:
    ensure => 'directory',
  }

  # Then we use the $file_name and $file_content parameters to create a file
  file { "${example_module::params::base_directory}/${example_module::params::file_name}":
    ensure  => 'file',
    content => $example_module::params::file_content,
  }
}
