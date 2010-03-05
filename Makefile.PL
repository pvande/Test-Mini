use inc::Module::Install;

use 5.008009;

name     'Test-Mini-Unit';
all_from 'lib/Test/Mini/Unit.pm';
author   'Pieter Vande Bruggen <pvande@local>';

requires 'B::Hooks::OP::Check' => '0.18';
requires 'Data::Inspect'       => '0.03';
requires 'Devel::Declare'      => '0.005011';
requires 'Exception::Class'    => '1.29';
requires 'List::Util'          => '1.21';
requires 'Moose'               => '0.98';
requires 'Moose::Autobox'      => '0.09';
requires 'MooseX::Declare'     => '0.31';
requires 'MooseX::Getopt'      => '0.22';
requires 'Scalar::Util'        => '1.21';
requires 'TryCatch'            => '1.002000';
requires 'Text::Outdent'       => '0.01';
requires 'IO-stringy'          => '2.110';

auto_provides_class;

WriteAll;
