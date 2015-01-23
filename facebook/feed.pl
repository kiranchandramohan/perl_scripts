#!/usr/bin/perl

use strict;
use warnings;
use open qw(:std :utf8);
use LWP::Simple;
use YAML::Tiny;
use JSON;
use URI;
use utf8;

my $access_token = '' ;

# Fetch your News Feed from Facebook
#my $resp = graph_api('me/home', { access_token => $access_token });
my $resp = graph_api('me/friends', { access_token => $access_token });
#my $resp = graph_api('me/groups', { access_token => $access_token });
for my $post (@{ $resp->{data} }) {
  # do something with each $post
  print "$post->{name}\n" ;
  #print Dump($post);
}

# Publish a new message to your own wall
#graph_api('me/feed', {
#  access_token => $access_token,
#  message      => 'Hello World! I’m posting Facebook updates from a script!',
#  link         => 'http://qscripts.blogspot.com/2011/02/post-to-your-own-facebook-account-from.html',
#  picture      => 'http://navarroj.com/stuff/share-icon-128x128.png',
#  name         => 'Post to your own Facebook account from a script',
#  caption      => 'qscripts.blogspot.com',
#  description  => 'You want to create a script to read messages and post status updates to your own '
#                . 'Facebook account, but you find the official documentation confusing and '
#                . 'you aren’t sure where to start. Search no more because here you’ll find '
#                . 'the easiest way to do just this.',
#  method       => 'post'
#});

exit 0;

sub graph_api {
  my $uri = new URI('https://graph.facebook.com/' . shift);
  $uri->query_form(shift);
  my $resp = get("$uri");
  return defined $resp ? decode_json($resp) : undef;
}
