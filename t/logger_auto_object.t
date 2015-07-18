#!/usr/bin/perl 
use strict;
use warnings;
use Test::More qw{no_plan};

BEGIN {

   use_ok('Test::Mini::Runner');
   can_ok('Test::Mini::Runner', qw{
      logger
   });

};
#-----------------------------------------------------------------
ok my $r  = Test::Mini::Runner->new;
isa_ok  $r, 'Test::Mini::Runner';

is $r->{logger}, 'Test::Mini::Logger::TAP';
isa_ok $r->logger, 'Test::Mini::Logger::TAP';
ok $r->{logger} = 'TAP';
isa_ok $r->logger, 'Test::Mini::Logger::TAP';

