#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Compress::Zlib;
use English qw(-no_match_vars);
use List::Util qw(first);
use Test::Deep;
use Test::Exception;
use Test::More;

use FusionInventory::Agent::Logger;
use FusionInventory::Agent::HTTP::Client::Fusion;
use FusionInventory::Agent::Message::Outbound;
use FusionInventory::Test::Server;
use FusionInventory::Test::Utils;

unsetProxyEnvVar();

# find an available port
my $port = first { test_port($_) } 8080 .. 8090;

if (!$port) {
    plan skip_all => 'no available port';
} else {
    plan tests => 7;
}

my $logger = FusionInventory::Agent::Logger->new(
    backends => [ 'Test' ]
);

my $message = FusionInventory::Agent::Message::Outbound->new(
    deviceid => 'foo',
    query => 'foo',
    msg => {
        foo => 'foo',
        bar => 'bar'
    },
);

my $client = FusionInventory::Agent::HTTP::Client::Fusion->new(
    logger => $logger
);

# http connection tests
my ($server, $response);

$server = FusionInventory::Test::Server->new(
    port => $port,
);
my $header  = "HTTP/1.0 200 OK\r\n\r\n";
my $xml_content  = "<REPLY><word>hello</word></REPLY>";
my $html_content = "<html><body>hello</body></html>";
$server->set_dispatch({
    '/error'        => sub { print "HTTP/1.0 403 NOK\r\n\r\n"; },
    '/empty'        => sub { print $header; },
    '/uncompressed' => sub { print $header . $html_content; },
    '/mixedhtml'   => sub { print $header . $html_content." a aee".$xml_content ; },
    '/unexpected'   => sub { print $header . compress($html_content); },
    '/correct'      => sub { print $header . compress($xml_content); },
    '/altered'      => sub { print $header . "\n" . compress($xml_content); },
});
$server->background() or BAIL_OUT("can't launch the server");

subtest "error response" => sub {
    check_response_nok(
        scalar $client->sendXML(
            message => $message,
            url     => "http://localhost:$port/error",
        ),
        $logger,
        "[http client] communication error: 403 NOK",
    );
};

subtest "empty content" => sub {
    check_response_nok(
        scalar $client->sendXML(
            message => $message,
            url     => "http://localhost:$port/empty",
        ),
        $logger,
        "[http client] unknown content format",
    );
};


subtest "mixedhtml content" => sub {
    check_response_ok(
        scalar $client->sendXML(
            message => $message,
            url     => "http://localhost:$port/mixedhtml",
        ),
    );
};


subtest "uncompressed content" => sub {
    check_response_nok(
        scalar $client->sendXML(
            message => $message,
            url     => "http://localhost:$port/uncompressed",
        ),
        $logger,
        "[http client] unexpected content, starting with $html_content",
    );
};

subtest "unexpected content" => sub {
    check_response_nok(
        scalar $client->sendXML(
            message => $message,
            url     => "http://localhost:$port/unexpected",
        ),
        $logger,
        "[http client] unexpected content, starting with $html_content",
    );
};

subtest "correct response" => sub {
    check_response_ok(
        scalar $client->sendXML(
            message => $message,
            url     => "http://localhost:$port/correct",
        ),
    );
};

subtest "altered response" => sub {
    check_response_ok(
        scalar $client->sendXML(
            message => $message,
            url     => "http://localhost:$port/altered",
        ),
    );
};

$server->stop();

sub check_response_ok {
    my ($response) = @_;

    plan tests => 3;
    ok(defined $response, "response from server");
    is(ref $response, 'HASH', "response format");
    cmp_deeply(
        $response,
        { word => 'hello' },
        'response content'
    );
}

sub check_response_nok {
    my ($response, $logger, $message) = @_;

    plan tests => 3;
    ok(!defined $response,  "no response");
    is(
        $logger->{backends}->[0]->{level},
        'error',
        "error message level"
    );
    if (ref $message eq 'Regexp') {
        like(
            $logger->{backends}->[0]->{message},
            $message,
            "error message content"
        );
    } else {
        is(
            $logger->{backends}->[0]->{message},
            $message,
            "error message content"
        );
    }
}
