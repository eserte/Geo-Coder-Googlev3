# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2010,2011 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Geo::Coder::Googlev3;

use strict;
use vars qw($VERSION);
our $VERSION = '0.06';

use Carp            ('croak');
use Encode          ();
use JSON::XS        ();
use LWP::UserAgent  ();
use URI		    ();
use URI::QueryParam ();

sub new {
    my($class, %args) = @_;
    my $self = bless {}, $class;
    $self->{ua}       = delete $args{ua} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION libwww-perl/$LWP::VERSION");
    $self->{region}   = delete $args{region} || delete $args{gl};
    $self->{language} = delete $args{language};
    croak "Unsupported arguments: " . join(" ", %args) if %args;
    $self;
}

sub ua {
    my $self = shift;
    if (@_) {
	$self->{ua} = shift;
    }
    $self->{ua};
}

sub geocode {
    my($self, %args) = @_;
    my $loc = $args{location};
    my $ua = $self->ua;
    my $url = URI->new('http://maps.google.com/maps/api/geocode/json');
    my %url_params;
    $url_params{address}  = $loc;
    $url_params{sensor}   = 'false';
    $url_params{region}   = $self->{region}   if defined $self->{region};
    $url_params{language} = $self->{language} if defined $self->{language};
    while(my($k,$v) = each %url_params) {
        $url->query_param($k => Encode::encode_utf8($v));
    }
    $url = $url->as_string;
    my $resp = $ua->get($url);
    if ($resp->is_success) {
	my $content = $resp->decoded_content(charset => "none");
	my $res = JSON::XS->new->utf8->decode($content);
	if ($res->{status} eq 'OK') {
            if (wantarray) {
                return @{ $res->{results} };
            } else {
                return $res->{results}->[0];
            }
	} else {
	    croak "Fetching $url did not return OK status, but '" . $res->{status} . "'";
	}
    } else {
	croak "Fetching $url failed: " . $resp->status_line;
    }
}

1;

__END__

=head1 NAME

Geo::Coder::Googlev3 - Google Maps v3 Geocoding API 

=head1 SYNOPSIS

    use Geo::Coder::Googlev3;

    my $geocoder = Geo::Coder::Googlev3->new;
    my $location  = $geocoder->geocode(location => 'Brandenburger Tor, Berlin');
    my @locations = $geocoder->geocode(location => 'Berliner Straﬂe, Berlin, Germany');

=head1 DESCRIPTION

Use this module just like L<Geo::Coder::Google>. Note that no
C<apikey> is used in Google's v3 API, and the returned data structure
differs.

Please check also
L<http://code.google.com/intl/en/apis/maps/documentation/geocoding/>
for more information about Google's Geocoding API and especially usage
limits.

=head2 CONSTRUCTOR

=over

=item new

    $geocoder = Geo::Coder::Googlev3->new;
    $geocoder = Geo::Coder::Googlev3->new(language => 'de', gl => 'es');

Creates a new geocoding object.

The L<Geo::Coder::Google>'s C<oe> and C<apikey> parameters are not
supported.

=back

=head2 METHODS

=over

=item geocode

    $location = $geocoder->geocode(location => $location);
    @locations = $geocoder->geocode(location => $location);

Queries I<$location> to Google Maps geocoding API. In scalar context
it returns a hash reference of the first (best matching?) location. In
list context it returns a list of such hash references.

The returned data structure looks like this:

  {
    "formatted_address" => "Brandenburger Tor, Pariser Platz 7, 10117 Berlin, Germany",
    "types" => [
      "point_of_interest",
      "establishment"
    ],
    "address_components" => [
      {
        "types" => [
          "point_of_interest",
          "establishment"
        ],
        "short_name" => "Brandenburger Tor",
        "long_name" => "Brandenburger Tor"
      },
      {
        "types" => [
          "street_number"
        ],
        "short_name" => 7,
        "long_name" => 7
      },
      {
        "types" => [
          "route"
        ],
        "short_name" => "Pariser Platz",
        "long_name" => "Pariser Platz"
      },
      {
        "types" => [
          "sublocality",
          "political"
        ],
        "short_name" => "Mitte",
        "long_name" => "Mitte"
      },
      {
        "types" => [
          "locality",
          "political"
        ],
        "short_name" => "Berlin",
        "long_name" => "Berlin"
      },
      {
        "types" => [
          "administrative_area_level_2",
          "political"
        ],
        "short_name" => "Berlin",
        "long_name" => "Berlin"
      },
      {
        "types" => [
          "administrative_area_level_1",
          "political"
        ],
        "short_name" => "Berlin",
        "long_name" => "Berlin"
      },
      {
        "types" => [
          "country",
          "political"
        ],
        "short_name" => "DE",
        "long_name" => "Germany"
      },
      {
        "types" => [
          "postal_code"
        ],
        "short_name" => 10117,
        "long_name" => 10117
      }
    ],
    "geometry" => {
      "viewport" => {
        "southwest" => {
          "lat" => "52.5094785",
          "lng" => "13.3617711"
        },
        "northeast" => {
          "lat" => "52.5230586",
          "lng" => "13.3937859"
        }
      },
      "location" => {
        "lat" => "52.5162691",
        "lng" => "13.3777785"
      },
      "location_type" => "APPROXIMATE"
    }
  };

=back  

=head1 AUTHOR

Slaven Rezic <srezic@cpan.org>

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Geo::Coder::Google>.

=cut

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
# vim:sw=4:ts=8:sta:et
