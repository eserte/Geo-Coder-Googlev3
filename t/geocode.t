# -*- coding:iso-8859-1; -*-

use strict;
use Test::More;

sub within ($$$$$$);

plan tests => 23;

use_ok 'Geo::Coder::Googlev3';

my $geocoder = Geo::Coder::Googlev3->new;
isa_ok $geocoder, 'Geo::Coder::Googlev3';

{
    my $location = $geocoder->geocode(location => 'Brandenburger Tor, Berlin, Germany');
    like $location->{formatted_address}, qr{brandenburger tor.*berlin}i;
    my($lat, $lng) = @{$location->{geometry}->{location}}{qw(lat lng)};
    within $lat, $lng, 52.5, 52.6, 13.3, 13.4;
}

{ # encoding checks - bytes
    my $location = $geocoder->geocode(location => 'Öschelbronner Weg, Berlin, Germany');
    like $location->{formatted_address}, qr{schelbronner weg.*berlin}i;
    my($lat, $lng) = @{$location->{geometry}->{location}}{qw(lat lng)};
    within $lat, $lng, 52.6, 52.7, 13.3, 13.4;
}

{ # encoding checks - utf8
    my $street = 'Öschelbronner Weg';
    utf8::upgrade($street);
    my $location = $geocoder->geocode(location => "$street, Berlin, Germany");
    like $location->{formatted_address}, qr{schelbronner weg.*berlin}i;
    my($lat, $lng) = @{$location->{geometry}->{location}}{qw(lat lng)};
    within $lat, $lng, 52.6, 52.7, 13.3, 13.4;
}

{ # encoding checks - more utf8
    my $street = "Trg bana Josipa Jela\x{10d}i\x{107}a";
    my $location = $geocoder->geocode(location => "$street, Zagreb, Croatia");
    like $location->{formatted_address}, qr{$street}i;
    my($lat, $lng) = @{$location->{geometry}->{location}}{qw(lat lng)};
    within $lat, $lng, 45.8, 45.9, 15.9, 16.0;
}

{
    my $postal_code = 'E1A 7G1';
    my $location = $geocoder->geocode(location => "$postal_code, Canada");
    my $postal_code_component;
    for my $address_component (@{ $location->{address_components} }) {
	if (grep { $_ eq 'postal_code' } @{ $address_component->{types} }) {
	    $postal_code_component = $address_component;
	    last;
	}
    }
    is $postal_code_component->{long_name}, $postal_code;
}

sub within ($$$$$$) {
    my($lat,$lng,$lat_min,$lat_max,$lng_min,$lng_max) = @_;
    cmp_ok $lat, ">=", $lat_min;
    cmp_ok $lat, "<=", $lat_max;
    cmp_ok $lng, ">=", $lng_min;
    cmp_ok $lng, "<=", $lng_max;
}

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:
# vim:ft=perl:et:sw=4
