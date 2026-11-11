# This lookup assigns classes via hiera instead of through site.pp
lookup('classes', Array[String], 'unique', []).include

# A default empty node is needed for puppet to get far enough to lookup classes from hiera...
node default { }
