use MooseX::Declare;

class Helper
{
  method doit(@) { die "It's all over!"; return @_ }
}