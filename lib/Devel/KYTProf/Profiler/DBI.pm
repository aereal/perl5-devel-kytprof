package Devel::KYTProf::Profiler::DBI;

use strict;
use warnings;
use DBIx::Tracer;

sub apply {
    Devel::KYTProf->add_prof(
        'DBI',
        'connect',
        sub {
            my ($orig, $class, $dsn, $user, $pass, $attr) = @_;
            return [
                '%s %s',
                ['dbi_connect_method', 'dsn'],
                {
                    dbi_connect_method => $attr->{dbi_connect_method} || 'connect',
                    dsn => $dsn,
                },
            ];
        }
    );

    my $LastSQL;
    my $LastBinds;
    my $IsInProf;

    our $_TRACER = DBIx::Tracer->new(sub {
        my %args = @_;
        $LastSQL = $args{sql};
        my $bind_params = $args{bind_params} || [];
        $LastBinds = scalar(@$bind_params) ?
            '(bind: '.join(', ', map { defined $_ ? $_ : 'undef' } @$bind_params).')' :
            '';
    });
    Devel::KYTProf->add_prof(
        'DBI::st',
        'execute',
        sub {
            my (undef, $sth) = @_;
            return [
                '%s %s (%d rows)',
                ['sql', 'sql_binds', 'rows'],
                {
                    sql       => $LastSQL,
                    sql_binds => $LastBinds,
                    rows      => $sth->rows,
                },
            ];
        },
        sub { !$IsInProf },
    );

    Devel::KYTProf->add_profs(
        'DBI::db',
        [qw/do selectall_arrayref selectrow_arrayref selectrow_array/],
        sub {
            undef $IsInProf;
            return [
                '%s %s',
                ['sql', 'sql_binds'],
                {
                    sql       => $LastSQL,
                    sql_binds => $LastBinds,
                },
            ];
        },
        # Since there is a possibility that these methods call `execute` method
        # internally (it depends on DBD implementation), we flag here to prevent
        # duplicate profiling output.
        # And we drop this flag in the above callback.
        sub { $IsInProf = 1 },
    );
}

1;
