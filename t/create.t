use Test::More tests => 2;
BEGIN {use_ok ('Net::Google::FederatedLogin')};

my $fl = Net::Google::FederatedLogin->new(claimed_id => 'rubbish@gmail.com');
isa_ok($fl, 'Net::Google::FederatedLogin');
