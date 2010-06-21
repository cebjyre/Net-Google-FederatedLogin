package Net::Google::FederatedLogin::Types;
# ABSTRACT: Types for Net-Google-FederatedLogin.

use Moose::Util::TypeConstraints;
use Net::Google::FederatedLogin::Extension;

subtype 'Extension_List',
    as 'HashRef[Net::Google::FederatedLogin::Extension]';

coerce 'Extension_List',
    from 'ArrayRef',
    via {my $ret = {map {($_->{uri} => Net::Google::FederatedLogin::Extension->new($_))} @$_};};

no Moose::Util::TypeConstraints;
1;
