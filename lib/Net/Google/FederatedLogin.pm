package Net::Google::FederatedLogin;
# ABSTRACT: Google Federated Login module - see http://code.google.com/apis/accounts/docs/OpenID.html

use Moose;

use LWP::UserAgent;

my $DEFAULT_DISCOVERY_URL = 'https://www.google.com/accounts/o8/id';

has username    => (
    is  => 'rw',
    isa => 'Str',
);

has ua  => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    default => sub {
        return LWP::UserAgent->new(agent => sprintf 'Net-Google-FederatedLogin/%s ', __PACKAGE__->VERSION);
    },
);

has return_to   => (
    is  => 'rw',
    isa => 'Str',
);

has _open_id_endpoint   => (
    is  => 'rw',
    isa => 'Str',
);

sub get_auth_url {
    my $self = shift;
    
    my $endpoint = $self->_open_id_endpoint;
    unless($endpoint) {
        $self->_perform_discovery;
        $endpoint = $self->_open_id_endpoint;
        die 'No OpenID endpoint found.' unless $endpoint;
    }
    
    $endpoint .=  $self->_get_request_parameters;
    
    return $endpoint;
}

sub _perform_discovery {
    my $self = shift;
    my $username = $self->username;
    die 'Username not set, unable to perform discovery' unless $username;
    
    #TODO: Check whether it is a Google Apps account
    my $ua = $self->ua;
    my $response = $ua->get($DEFAULT_DISCOVERY_URL,
        Accept => 'application/xrds+xml');
    
    require XML::Twig;
    my $xt = XML::Twig->new(
        twig_handlers => { URI => sub {$self->_open_id_endpoint($_->text)}},
    );
    $xt->parse($response->decoded_content);
}

sub _get_request_parameters {
    my $self = shift;
    
    die 'No return_to address provided' unless $self->return_to;
    my $params = '?openid.mode=checkid_setup'
        . '&openid.ns=http://specs.openid.net/auth/2.0'
        . '&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select'
        . '&openid.identity=http://specs.openid.net/auth/2.0/identifier_select'
        . '&openid.return_to=' . $self->return_to;
    
    return $params;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

