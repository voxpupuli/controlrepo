class profiles::hdm {
 class { 'hdm':
   version => '4.0.0',
 }
 contain hdm
}
