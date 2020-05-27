use Test;
plan 3;
use-ok 'Radamsa';

use Radamsa;
my $r = radamsa.new('testing');

isa-ok $r, 'radamsa', 'libloading works';

my $b8 = $r.gen1;
isa-ok $b8, 'Buf[uint8]', 'returns results';

