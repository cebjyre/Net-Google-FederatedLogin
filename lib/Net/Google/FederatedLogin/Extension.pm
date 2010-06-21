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
    $params .= _parameterise_hash("openid.$ns", $attributes);
    
    return $params;
}

sub _parameterise_hash {
    my $prefix = shift;
    my $hash = shift;
    
    my $params = '';
    foreach(sort keys %$hash) {
        my $value = $hash->{$_};
        if(ref $value eq 'HASH') {
            $params .= _parameterise_hash("$prefix.$_", $value);
        }
        else {
            $params .= sprintf '&%s.%s=%s', $prefix, $_, $value;
        }
    }
    return $params;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
