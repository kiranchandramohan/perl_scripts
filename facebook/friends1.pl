#!/usr/bin/perl
use WWW::Facebook::API;

# @ENV{qw/WFA_API_KEY WFA_SECRET WFA_DESKTOP/} are the initial values,
# so use those if you only have one app and don't want to pass in values
# to constructor
my $client = WWW::Facebook::API->new(
    desktop => 1,
    api_key => '210361752461159',
    secret => 'cef69788d0d7796feda5bc97371ac4e2',
);

## Change API key and secret
#print "Enter your public API key: ";
#chomp( my $val = <STDIN> );
#$client->api_key($val);
#print "Enter your API secret: ";
#chomp($val = <STDIN> );
#$client->secret($val);

# not needed if web app (see $client->canvas->get_fb_params)
#$client->auth->get_session( $token );
my $token = $client->auth->create_token ;
print "Token = $token\n" ;
$client->auth->get_session($token) ;

use Data::Dumper;
my $friends_perl = $client->friends->get;
print Dumper $friends_perl;

#my $notifications_perl = $client->notifications->get;
#print Dumper $notifications_perl;
#
## Current user's quotes
#my $quotes_perl = $client->users->get_info(
#    uids   => $friends_perl,
#    fields => ['quotes']
#);
#print Dumper $quotes_perl;

$client->auth->logout;
