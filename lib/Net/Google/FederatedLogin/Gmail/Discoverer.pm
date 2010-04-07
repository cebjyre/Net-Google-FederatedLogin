package Net::Google::FederatedLogin::Gmail::Discoverer;
# ABSTRACT: Find the OpenID endpoint for standard gmail accounts

use Moose;

with 'Net::Google::FederatedLogin::Role::Discoverer';

my $DISCOVERY_URL = 'https://www.google.com/accounts/o8/id';

sub perform_discovery {
    my $self = shift;
    
    my $ua = $self->ua;
    my $response = $ua->get($DISCOVERY_URL,
        Accept => 'application/xrds+xml');
    
    my $open_id_endpoint;
    
    require XML::Twig;
    my $xt = XML::Twig->new(
        twig_handlers => { URI => sub {$open_id_endpoint = $_->text}},
    );
    $xt->parse($response->decoded_content);
    
    return $open_id_endpoint;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
