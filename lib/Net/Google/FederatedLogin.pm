package Net::Google::FederatedLogin;
# ABSTRACT: Google Federated Login module - see http://code.google.com/apis/accounts/docs/OpenID.html

use Moose;

use LWP::UserAgent;

my $DEFAULT_DISCOVERY_URL = 'https://www.google.com/accounts/o8/id';

has username => (
    is  => 'rw',
    isa => 'Str',
);

has ua => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    default => sub {
        return LWP::UserAgent->new(agent => sprintf 'Net-Google-FederatedLogin/%s ', __PACKAGE__->VERSION);
    },
);

has _open_id_endpoint => (
    is => 'rw',
    isa => 'Str',
);

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

no Moose;
__PACKAGE__->meta->make_immutable;

1;

