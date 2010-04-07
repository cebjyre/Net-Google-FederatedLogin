package Net::Google::FederatedLogin::Role::Discoverer;
# ABSTRACT: something that can find the OpenID endpoint

use Moose::Role;

requires 'perform_discovery';

has ua => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    required    => 1,
);

no Moose::Role;
1;
