use MooseX::Declare;

class Mini::Unit is dirty
{
  use aliased 'MooseX::Declare::Syntax::Keyword::Class', 'ClassKeyword';
  use aliased 'MooseX::Declare::Syntax::Keyword::Role',  'RoleKeyword';
  use aliased 'Mini::Unit::Syntax::Keyword::TestCase',   'TestCaseKeyword';

  sub keywords {
    ClassKeyword->new(identifier => 'class'),
    RoleKeyword->new(identifier => 'role'),
    TestCaseKeyword->new(identifier => 'testcase'),
  }

  clean;

  method import(ClassName $class: %args)
  {
    my $caller = caller();

    strict->import;
    warnings->import;

    for my $keyword (keywords()) {
      $keyword->setup_for($caller, %args, provided_by => $class);
    }
  }
}


use Mini::Unit::Runner;
# $Carp::CarpLevel = 'Infinity';

END {
  $| = 1;
  return if $?;
  $? = Mini::Unit::Runner->new_with_options()->run();
}
