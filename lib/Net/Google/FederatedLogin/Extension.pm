package Net::Google::FederatedLogin::Extension;
# ABSTRACT: something that can find the OpenID endpoint

use Moose;

has ns          => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

has uri         => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

has attributes  => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
);

sub get_parameters {
    my $self = shift;
    my $ns = $self->ns;
    
    my $params = sprintf 'openid.ns.%s=%s', $ns, $self->uri;
    
    my $attributes = $self->attributes;
    foreach(sort keys %$attributes) {
        $params .= sprintf '&openid.%s.%s=%s', $ns, $_, $attributes->{$_};
    }
    
    return $params;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
