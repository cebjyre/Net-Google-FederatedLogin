package Net::Google::FederatedLogin::Apps::Discoverer;
# ABSTRACT: Find the OpenID endpoint for apps domain accounts

use Moose;

with 'Net::Google::FederatedLogin::Role::Discoverer';

use Carp;
use URI::Escape;

has app_domain  => (
    is  => 'rw',
    isa => 'Str',
    required    => 1,
);

has claimed_id  => (
    is  => 'rw',
    isa => 'Str',
);

=method perform_discovery

Perform OpenID endpoint discovery for hosted domains - see
http://groups.google.com/group/google-federated-login-api/web/openid-discovery-for-hosted-domains?pli=1
for more details.

=cut

sub perform_discovery {
    my $self = shift;
    
    my $ua = $self->ua;
    my $response = $ua->get($self->_get_discovery_url,
        Accept => 'application/xrds+xml');
    
    my $open_id_endpoint;
    
    require XML::Twig;
    my $twig_handlers = {};
    if(my $claimed_id = $self->claimed_id) {
        my $escaped_id = uri_escape($claimed_id);
        $twig_handlers->{Service} = sub {
            if($_->first_child_text('Type') eq 'http://www.iana.org/assignments/relation/describedby') {
                $open_id_endpoint = $_->first_child_text('openid:URITemplate');
                $open_id_endpoint =~ s/{%uri}/$escaped_id/;
            }
        }
    } else {
        $twig_handlers->{URI} = sub {$open_id_endpoint = $_->text};
    }
    my $xt = XML::Twig->new(
        twig_handlers => $twig_handlers,
    );
    $xt->parse($response->decoded_content);
    
    return $open_id_endpoint;
}

sub _get_discovery_url {
    my $self = shift;
    
    my $app_domain = $self->app_domain;
    
    #Check google hosted
    my $host_meta_url = 'https://www.google.com/accounts/o8/.well-known/host-meta?hd=' . $app_domain;
    my $ua = $self->ua;
    my $response = $ua->get($host_meta_url);
    unless($response->is_success) { #fallback to the domain specific location
        $host_meta_url = sprintf 'http://%s/.well-known/host-meta', $app_domain;
        $response = $ua->get($host_meta_url);
    }
    unless($response->is_success) {
        croak 'Unable to find a host-meta page.';
    }
    if($response->decoded_content =~ m{Link: <(.+)>; \Qrel="describedby http://reltype.google.com/openid/xrd-op"; type="application/xrds+xml"\E}) {
        return $1;
    } else {
        croak 'Unable to perform discovery - host-meta page is not as expected.'
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
