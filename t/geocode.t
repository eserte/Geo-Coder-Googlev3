# -*- coding:iso-8859-1; -*-

use strict;
use Test::More;

sub within ($$$$$$);

plan tests => 30;

use_ok 'Geo::Coder::Googlev3';

my $geocoder = Geo::Coder::Googlev3->new;
isa_ok $geocoder, 'Geo::Coder::Googlev3';

{ # list context
    ## There are eight hits in Berlin. Google uses to know seven of them.
    ## But beginning from approx. 2010-05, only one location is returned.
    #my @locations = $geocoder->geocode(location => 'Berliner Straße, Berlin, Germany');
    #cmp_ok scalar(@locations), ">=", 1, "One or more results found";
    #like $locations[0]->{formatted_address}, qr{Berliner Straße}, 'First result looks OK';

    my @locations = $geocoder->geocode(location => 'Waterloo, UK');
    cmp_ok scalar(@locations), ">", 1, "More than one result found";
    like $locations[0]->{formatted_address}, qr{Waterloo}, 'First result looks OK';
}

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
    my $alternative = "Ban Jela\x{10d}i\x{107} Square"; # outcome as of 2011-02-02
    my $alternative2 = 'City of Zagreb, Croatia'; # happened once in February 2011, see http://www.cpantesters.org/cpan/report/447c31b8-6cb5-1014-b648-c13506c0976e
    my $location = $geocoder->geocode(location => "$street, Zagreb, Croatia");
    like $location->{formatted_address}, qr{($street|$alternative|$alternative2)}i;
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

{ # region
    my $geocoder_es = Geo::Coder::Googlev3->new(gl => 'es', language => 'de');
    my $location_es = $geocoder_es->geocode(location => 'Toledo');
    is $location_es->{geometry}->{location}->{lng}, '-4.0244759';
    my $geocoder_us = Geo::Coder::Googlev3->new();
    my $location_us = $geocoder_us->geocode(location => 'Toledo');
    is $location_us->{geometry}->{location}->{lng}, '-83.555212';
}

{ # zero results
    my @locations = $geocoder->geocode(location => 'This query should not find anything but return ZERO_RESULTS, Foobartown');
    cmp_ok scalar(@locations), "==", 0, "No result found";

    my $location = $geocoder->geocode(location => 'This query should not find anything but return ZERO_RESULTS, Foobartown');
    is $location, undef, "No result found";
}

{ # raw
    my $raw_result = $geocoder->geocode(location => 'Brandenburger Tor, Berlin, Germany', raw => 1);
    # This is the 11th query here, so it's very likely that the API
    # limits are hit.
    like $raw_result->{status}, qr{^(OK|OVER_QUERY_LIMIT)$}, 'raw query';
    if ($raw_result->{status} eq 'OVER_QUERY_LIMIT') {
	diag 'over query limit hit, sleep a little bit';
	sleep 1; # in case a smoker tries this module with another perl...
    }
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
