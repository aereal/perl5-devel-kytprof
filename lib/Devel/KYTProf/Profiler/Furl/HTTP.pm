package Devel::KYTProf::Profiler::Furl::HTTP;

use strict;
use warnings;

sub apply {
    Devel::KYTProf->add_prof(
        'Furl::HTTP',
        'request',
        sub {
            my ($orig, $self, %args) = @_;

            my $method = $args{method} || 'GET';
            my $url = do {
                if (defined $args{url}) {
                    $args{url};
                } else {
                    my $scheme = $args{scheme} || 'http';
                    my $port = $args{port} || '';
                    my $host = $args{host} || '';
                    my $path_query = $args{path_query} || '';
                    sprintf('%s://%s%s%s',
                        $scheme,
                        $host,
                        $port ? ":$port" : '',
                        substr($path_query, 0, 1) eq '/' ? $path_query : "/$path_query",
                    );
                }
            };

            return [
                '%s %s',
                ['http_method', 'http_url'],
                {
                    http_method => $method,
                    http_url    => $url,
                },
            ];
        },
    );
}

1;
