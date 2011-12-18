# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2011 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package TestUtil;

use strict;
use vars qw($VERSION @EXPORT);
$VERSION = '0.01';

use base qw(Exporter);
@EXPORT = qw(is_float);

use POSIX qw(DBL_EPSILON);

sub is_float ($$;$) {
    my($value, $expected, $testname) = @_;
    local $Test::Builder::Level = $Test::Builder::Level+1;
    my @value    = split /[\s,]+/, $value;
    my @expected = split /[\s,]+/, $expected;
    my $ok = 1;
    for my $i (0 .. $#value) {
        if ($expected[$i] =~ /^[\d+-]/) {
            if (abs($value[$i]-$expected[$i]) > DBL_EPSILON) {
                $ok = 0;
                last;
            }
        } else {
            if ($value[$i] ne $expected[$i]) {
                $ok = 0;
                last;
            }
        }
    }
    if ($ok) {
        Test::More::pass($testname);
    } else {
        Test::More::is($value, $expected, $testname); # will fail
    }
}

1;

__END__
