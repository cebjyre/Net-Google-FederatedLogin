package Net::Google::FederatedLogin;
# ABSTRACT: Google Federated Login module - see http://code.google.com/apis/accounts/docs/OpenID.html

use Moose;

use LWP::UserAgent;
use Carp;
use URI::Escape;

my $DEFAULT_DISCOVERY_URL = 'https://www.google.com/accounts/o8/id';

=attr claimed_id

B<Required for L<get_auth_url>:> The email address, or an OpenID URL of the identity to be checked.

=cut

has claimed_id    => (
    is  => 'rw',
    isa => 'Str',
);

=attr ua

The useragent internally used for communications that the
module needs to do. If not provided, a new L<LWP::UserAgent>
will be instantiated.

=cut

has ua  => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    default => sub {
        return LWP::UserAgent->new(agent => sprintf 'Net-Google-FederatedLogin/%s ', __PACKAGE__->VERSION);
    },
);

=attr return_to

B<Required for L<get_auth_url> and L<verify_auth>:> The URL
the user should be returned to after verifying their identity.

=cut

has return_to   => (
    is  => 'rw',
    isa => 'Str',
);

=attr cgi

B<Required for L<verify_auth>:> A CGI object that is used to
access the parameters that assert the identity has been verified.

=cut

has cgi => (
    is  => 'rw',
    isa => 'CGI',
);

has _open_id_endpoint   => (
    is  => 'rw',
    isa => 'Str',
);

=method get_auth_url

Gets the URL to send the user to where they can verify their identity.

=cut

sub get_auth_url {
    my $self = shift;
    
    my $endpoint = $self->_open_id_endpoint;
    unless($endpoint) {
        $self->_perform_discovery;
        $endpoint = $self->_open_id_endpoint;
        croak 'No OpenID endpoint found.' unless $endpoint;
    }
    
    $endpoint .=  $self->_get_request_parameters;
    
    return $endpoint;
}

sub _perform_discovery {
    my $self = shift;
    
    my $ua = $self->ua;
    my $response = $ua->get($self->_get_discovery_url,
        Accept => 'application/xrds+xml');
    
    require XML::Twig;
    my $xt = XML::Twig->new(
        twig_handlers => { URI => sub {$self->_open_id_endpoint($_->text)}},
    );
    $xt->parse($response->decoded_content);
}

sub _get_discovery_url {
    my $self = shift;
    
    my $claimed_id = $self->claimed_id;
    croak 'Claimed id not set (needs to be an email or OpenID url), unable to perform discovery' unless $claimed_id;
    
    #TODO: Check whether it is a Google Apps account
    return $DEFAULT_DISCOVERY_URL;
}

sub _get_request_parameters {
    my $self = shift;
    
    croak 'No return_to address provided' unless $self->return_to;
    my $params = '?openid.mode=checkid_setup'
        . '&openid.ns=http://specs.openid.net/auth/2.0'
        . '&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select'
        . '&openid.identity=http://specs.openid.net/auth/2.0/identifier_select'
        . '&openid.return_to=' . $self->return_to;
    
    return $params;
}

=method verify_auth

Checks if the user has been validated based on the parameters in the L<cgi> object,
and checks that these parameters do come from the correct OpenID provider (rather
than having been hand-crafted to appear to validate the identity).

=cut

sub verify_auth {
    my $self = shift;
    
    my $cgi = $self->cgi;
    croak 'No CGI provided (needed to verify OpenID parameters)' unless $cgi;
    
    return if $cgi->param('openid.mode') eq 'cancel';
    
    my $return_to = $self->return_to;
    my $param_return_to = $cgi->param('openid.return_to');
    croak 'Return_to value must be set for validation purposes' unless $return_to;
    croak sprintf q{Return_to parameter (%s) doesn't match provided value(%s)}, $param_return_to, $return_to unless $param_return_to eq $return_to;
    
    my $claimed_id = $self->claimed_id;
    my $param_claimed_id = $cgi->param('openid.claimed_id');
    if(!$claimed_id) {
        $self->claimed_id($param_claimed_id);
    } elsif ($claimed_id ne $param_claimed_id) {
        carp "Identity from parameters ($param_claimed_id) is not the same as the previously set claimed identity ($claimed_id); using the parameter version.";
        $self->claimed_id($param_claimed_id);
    }
    $self->_open_id_endpoint('');
    $self->_perform_discovery;
    
    my $verify_endpoint = $self->_open_id_endpoint;
    croak 'Unable to verify auth, failed to determine endpoint' unless $verify_endpoint;
    $verify_endpoint .= '?' . join '&',
        map {
            my $param = $_;
            my $val = $cgi->param($param);
            $val = 'check_authentication' if $param eq 'openid.mode';
            sprintf '%s=%s', uri_escape($param), uri_escape($val);
        } $cgi->param;
    
    my $ua = $self->ua;
    my $response = $ua->get($verify_endpoint,
        Accept => 'text/plain');
    my $response_data = _parse_direct_response($response);
    croak "Unexpected verification response namespace: $response_data->{ns}" unless $response_data->{ns} eq 'http://specs.openid.net/auth/2.0';
    
    return unless $response_data->{is_valid} eq 'true';
    return $param_claimed_id;
}

sub _parse_direct_response {
    my $response = shift;
    
    my $response_content = $response->decoded_content;
    my @lines = split /\n/, $response_content;
    my %data = map {my ($key, $value) = split /:/, $_, 2; $key => $value} @lines;
    return \%data;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

