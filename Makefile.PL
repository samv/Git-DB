use inc::Module::Install;

name 'Git-DB';
version '0.01';
author 'Sam Vilain <samv@cpan.org>';
repository 'git://github.com/samv/Git-DB';
license 'perl';

# apologies if these versions are inconveniently new - positive test
# results with earlier versions accepted.
#requires perl => 5.010;
requires "Moose" => 1.23;
requires "Sub::Exporter" => 0.982;
requires "boolean" => 0.28;
requires "Math::BigRat" => 0;

test_requires 'IO::Scalar';

#include 'Test::Exception';
#include 'Sub::Uplevel';

auto_install;

WriteAll;

