use Test::More tests => 1;

use Test::Mock::LWP;
$Mock_ua->set_isa('LWP::UserAgent');

use Net::Google::FederatedLogin;
my $fl = Net::Google::FederatedLogin->new(claimed_id => 'example@gmail.com', return_to => 'http://example.com/return');

$Mock_ua->mock(get => sub {
        my $self = shift;
        my $url = shift;
        die 'Unexpected request URL: ' . $url unless $url eq 'https://www.google.com/accounts/o8/id';
        return $Mock_response;
    }
);

$Mock_response->mock(decoded_content => sub {
        return q{<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
  <XRD>
  <Service priority="0">
  <Type>http://specs.openid.net/auth/2.0/server</Type>
  <Type>http://openid.net/srv/ax/1.0</Type>
  <Type>http://specs.openid.net/extensions/ui/1.0/mode/popup</Type>
  <Type>http://specs.openid.net/extensions/ui/1.0/icon</Type>
  <Type>http://specs.openid.net/extensions/pape/1.0</Type>
  <URI>https://www.google.com/accounts/o8/ud</URI>
  </Service>
  </XRD>
</xrds:XRDS>};
    }
);

my $auth_url = $fl->get_auth_url();
is($auth_url, 'https://www.google.com/accounts/o8/ud'
    .'?openid.mode=checkid_setup'
    .'&openid.ns=http://specs.openid.net/auth/2.0'
    .'&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select'
    .'&openid.identity=http://specs.openid.net/auth/2.0/identifier_select'
    .'&openid.return_to=http://example.com/return');
