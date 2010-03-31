package Net::Google::FederatedLogin;
# ABSTRACT: Google Federated Login module - see http://code.google.com/apis/accounts/docs/OpenID.html

use Moose;

my $DEFAULT_DISCOVERY_URL = 'https://www.google.com/accounts/o8/id';

has username => (
    is  => 'rw',
    isa => 'Str',
);

has open_id_endpoint => (
    is => 'ro',
    isa => 'Str',
);

sub perform_discovery {
    my $self = shift;
    my $username = $self->username;
    die 'Username not set, unable to perform discovery' unless $username;
    
    #TODO: Check whether it is a Google Apps account
    
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

