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
our $VERSION = '0.01';

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
	    return $res->{results}->[0];
	} else {
	    croak "Fetching $url did not return OK status";
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
    my $location = $geocoder->geocode(location => 'Brandenburger Tor, Berlin');

=head1 DESCRIPTION

Use this module just like L<Geo::Coder::Google>. Note that no
C<apikey> is used in Google's v3 API, and the returned result object
differs.

Please check also
L<http://code.google.com/intl/en/apis/maps/documentation/geocoding/>
for more information about Google's Geocoding API and especially usage
limits.

=head1 AUTHOR

Slaven Rezic <srezic@cpan.org>

=head1 SEE ALSO

L<Geo::Coder::Google>.

=cut

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
# vim:sw=4:ts=8:sta:et
