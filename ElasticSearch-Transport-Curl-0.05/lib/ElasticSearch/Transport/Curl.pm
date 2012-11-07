package ElasticSearch::Transport::Curl;

use strict;
use warnings FATAL => 'all';
use WWW::Curl::Easy;
use Encode qw(decode_utf8 encode_utf8);
use ElasticSearch 0.60;
use parent 'ElasticSearch::Transport';

our $VERSION = '0.05';

#===================================
sub protocol     {'http'}
sub default_port {9200}
#===================================

#===================================
sub send_request {
#===================================
    my $self   = shift;
    my $server = shift;
    my $params = shift;

    my $method = $params->{method};
    my $uri = $self->http_uri( $server, $params->{cmd}, $params->{qs} );

    my $client = $self->client;
    $client->setopt( CURLOPT_URL, $uri );

    my $data = $params->{data};
    $data = ''
        if !defined $data
        and $method eq 'POST' || $method eq 'PUT';

    if ( defined $data ) {
        $data = encode_utf8($data);
        $self->check_content_length( \$data );
        $client->setopt( CURLOPT_POSTFIELDS,    $data );
        $client->setopt( CURLOPT_POSTFIELDSIZE, length $data );
    }

    $client->setopt( CURLOPT_CUSTOMREQUEST, $method );
    $client->setopt( CURLOPT_NOBODY,        1 )
        if $method eq 'HEAD';

    $client->setopt( CURLOPT_HTTPHEADER, ['Expect:'] );
    $client->setopt( CURLOPT_ENCODING, 'deflate' )
        if $self->deflate;

    my $content;
    $client->setopt( CURLOPT_WRITEDATA, \$content );

    my $retcode = $client->perform;
    $content = decode_utf8($content)
        if defined $content;

    my ( $code, $msg );
    if ( $retcode == 0 ) {
        $code = $client->getinfo(CURLINFO_RESPONSE_CODE);
        return $content if $code >= 200 && $code <= 209;
        $msg = $self->http_status($code);
    }
    else {
        $msg = $client->strerror($retcode) . " ($retcode) " . $client->errbuf;
        $code = $retcode;
    }

    my $type = $self->code_to_error($code)
        || (
        $code eq '28'
        ? 'Timeout'
        : $code  eq '7'     # can't connect
        || $code eq '55'    # can't write
        || $code eq '56'    # can't read
        || $code eq '18'    # partial file
        || $code eq '25'    # upload failed
        ? 'Connection'
        : 'Request'
        );

    my $error_params = {
        server      => $server,
        status_code => $code,
        status_msg  => $msg,
    };

    if ( $type eq 'Request' or $type eq 'Conflict' or $type eq 'Missing' ) {
        $error_params->{content} = $content;
    }
    $self->throw( $type, $msg . ' (' . $code . ')', $error_params );
}

#===================================
sub client {
#===================================
    my $self = shift;
    unless ( $self->{_client}{$$} ) {
        my $client = WWW::Curl::Easy->new;
        $client->setopt( CURLOPT_TIMEOUT, $self->timeout );
        $client->setopt( CURLOPT_HEADER,  0 );
        $client->setopt( CURLOPT_VERBOSE, 0 );
        $self->{_client} = { $$ => $client };

    }
    my $client = $self->{_client}{$$};
    $client->setopt( CURLOPT_HTTPGET, 1 );
    return $client;
}

# ABSTRACT: A libcurl based HTTP backend for ElasticSearch


1;

__END__
=pod

=head1 NAME

ElasticSearch::Transport::Curl - A libcurl based HTTP backend for ElasticSearch

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use ElasticSearch;
    my $e = ElasticSearch->new(
        servers     => 'search.foo.com:9200',
        transport   => 'curl',
        timeout     => '10',
    );

=head1 DESCRIPTION

ElasticSearch::Transport::Curl uses L<WWW::Curl> and thus
L<libcurl|http://curl.haxx.se/libcurl/> to talk to ElasticSearch
over HTTP.

This is by far the fastest HTTP backend - 60% faster than the next fastest
L<ElasticSearch::Transport::HTTPTiny>, but does require a C compiler.

=head1 SEE ALSO

=over

=item * L<ElasticSearch>

=item * L<ElasticSearch::Transport>

=item * L<ElasticSearch::Transport::HTTPLite>

=item * L<ElasticSearch::Transport::HTTPTiny>

=item * L<ElasticSearch::Transport::Curl>

=item * L<ElasticSearch::Transport::AEHTTP>

=item * L<ElasticSearch::Transport::AECurl>

=item * L<ElasticSearch::Transport::Thrift>

=back

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

