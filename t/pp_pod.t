use strict;
use warnings;

use Test::More;
use PDL::PP qw(Foo::Bar Foo::Bar foobar);

# call pp_def and report args
sub call_pp_def {
    my $obj = pp_def(@_);
    $obj;
}

# search and remove pattern in generated pod:
sub find_usage {
    my ($obj, $str) = @_;
    my $res = $obj->{UsageDoc} =~ s/^\s+\Q$str\E;.*?(\n+|\z)//m;
    diag "Not found '$str' in: ", $obj->{UsageDoc} if !$res;
    $res;
}

# all checked?
sub all_seen {
    my ($obj, $str) = @_;
    my $res = $obj->{UsageDoc} !~ /^.*?\b$str\b.*?;.*$/m;
    diag "Still: ", $obj->{UsageDoc} if !$res;
    $res;
}

pp_bless('Foo::Bar');

subtest a => sub {
    my $obj = call_pp_def(foo =>
        Pars => 'a(n)',
    );
    ok find_usage($obj, 'foo($a)'), 'function call';
    ok find_usage($obj, '$a->foo'), 'method call';
    ok all_seen($obj, 'foo'), 'all seen';
};

subtest a_n => sub {
    my $obj = call_pp_def(foo =>
        Pars => 'a(n)',
        NoExport => 1,
    );
    ok find_usage($obj, '$a->foo'), 'method call';
    ok find_usage($obj, 'Foo::Bar::foo($a)'), 'no-exp function call';
    ok all_seen($obj, 'foo'), 'all seen';
};

subtest a_b_noi => sub {
    my $obj = call_pp_def(foo =>
        Pars => 'a(n); [o]b(n)',
        NoExport => 1,
        Overload => ['foo', 1],
        Inplace => ['a'],
    );
    ok find_usage($obj, '$b = foo $a'), 'operator';
    ok find_usage($obj, '$b = $a->foo'), 'method call';
    ok find_usage($obj, '$a->foo($b)'), 'method, all args';
    ok find_usage($obj, '$a->inplace->foo'), 'method, inplace';
    ok find_usage($obj, '$b = Foo::Bar::foo($a)'), 'function call';
    ok find_usage($obj, 'Foo::Bar::foo($a, $b)'), 'all args';
    ok find_usage($obj, 'Foo::Bar::foo($a->inplace)'), 'function, inplace';
    ok all_seen($obj, 'foo'), 'all seen';
};

subtest a_b_oi => sub {
    my $obj = call_pp_def(foo =>
        Pars => 'a(n); [o]b(n)',
        Overload => ['foo', 1],
        Inplace => ['a'],
    );
    ok find_usage($obj, '$b = foo $a'), 'operator';
    ok find_usage($obj, '$b = foo($a)'), 'function call';
    ok find_usage($obj, 'foo($a, $b)'), 'all args';
    ok find_usage($obj, '$b = $a->foo'), 'method call';
    ok find_usage($obj, '$a->foo($b)'), 'method, all args';
    ok find_usage($obj, 'foo($a->inplace)'), 'function, inplace';
    ok find_usage($obj, '$a->inplace->foo'), 'method, inplace';
    ok all_seen($obj, 'foo'), 'all seen';
};

subtest a_b => sub {
    my $obj = call_pp_def(foo =>
      Pars => 'a(n); [o]b(n)',
    );
    ok find_usage($obj, '$b = foo($a)'), 'function call w/ arg';
    ok find_usage($obj, 'foo($a, $b)'), 'all arguments given';
    ok find_usage($obj, '$b = $a->foo'), 'method call';
    ok find_usage($obj, '$a->foo($b)'), 'method call, arg';
    ok all_seen($obj, 'foo'), 'all seen';
};

subtest a_b_k => sub {
    my $obj = call_pp_def(foo =>
        Pars => 'a(n); [o]b(n)',
        OtherPars => 'int k',
    );
    ok find_usage($obj, '$b = foo($a, $k)'), 'function call w/ arg';
    ok find_usage($obj, 'foo($a, $b, $k)'), 'all arguments given';
    ok find_usage($obj, '$b = $a->foo($k)'), 'method call';
    ok find_usage($obj, '$a->foo($b, $k)'), 'method call, arg';
    ok all_seen($obj, 'foo'), 'all seen';
};

subtest ab_c_o => sub {
    my $obj = call_pp_def(foo =>
        Pars => 'a(n); b(n); [o]c(n)',
        Overload => '?:',
    );
    ok find_usage($obj, '$c = $a ?: $b'), 'biop';
    ok find_usage($obj, '$c = foo($a, $b)'), 'function';
    ok find_usage($obj, 'foo($a, $b, $c)'), 'function, all args';
    ok find_usage($obj, '$c = $a->foo($b)'), 'method';
    ok find_usage($obj, '$a->foo($b, $c)'), 'method, all args';
    ok all_seen($obj, 'foo'), 'all seen';
};

subtest ab_c_oi => sub {
    my $obj = call_pp_def(foo =>
        Pars => 'a(n); b(n); [o]c(n)',
        Overload => ['?:', 1],
        Inplace => ['a'],
    );
    ok find_usage($obj, '$c = $a ?: $b'), 'biop';
    ok find_usage($obj, '$c = foo($a, $b)'), 'function';
    ok find_usage($obj, 'foo($a, $b, $c)'), 'function, all args';
    ok find_usage($obj, '$c = $a->foo($b)'), 'method';
    ok find_usage($obj, '$a->foo($b, $c)'), 'method, all args';
    ok find_usage($obj, '$a ?:= $b'), 'mutator';
    ok find_usage($obj, 'foo($a->inplace, $b)'), 'inplace function call';
    ok find_usage($obj, '$a->inplace->foo($b)'), 'inplace method call';
    ok all_seen($obj, 'foo'), 'all seen';
};

subtest ab_c_ni => sub {
    my $obj = call_pp_def(foo =>
        Pars => 'a(n); b(n); [o]c(n)',
        Inplace => ['a'],
        NoExport => 1,
    );
    ok find_usage($obj, '$c = Foo::Bar::foo($a, $b)'), 'function';
    ok find_usage($obj, '$c = $a->foo($b)'), 'method';
    ok find_usage($obj, '$a->foo($b, $c)'), 'method, all args';
    ok find_usage($obj, '$a->inplace->foo($b)'), 'inplace method call';
    ok find_usage($obj, 'Foo::Bar::foo($a, $b, $c)'), 'function, all args';
    ok find_usage($obj, 'Foo::Bar::foo($a->inplace, $b)'), 'inplace function call';
    ok all_seen($obj, 'foo'), 'all seen';
};

subtest ab_c_o => sub {
    my $obj = call_pp_def(foo =>
        Pars => 'a(n); b(n); [o]c(n)',
        Overload => ['rho'],
    );
    ok find_usage($obj, '$c = foo($a, $b)'), 'function';
    ok find_usage($obj, 'foo($a, $b, $c)'), 'function, all args';
    ok find_usage($obj, '$c = $a->foo($b)'), 'method';
    ok find_usage($obj, '$a->foo($b, $c)'), 'method, all args';
    ok find_usage($obj, '$c = rho $a, $b'), 'prefix biop';
    ok all_seen($obj, 'foo'), 'all seen';
};

subtest ab_c_no => sub {
    my $obj = call_pp_def(foo =>
        Pars => 'a(n); b(n); [o]c(n)',
        Overload => ['rho', 0, 0, 1],
        NoExport => 1,
    );
    ok find_usage($obj, '$c = rho $a, $b'), 'prefix biop';
    ok find_usage($obj, '$c = $a->foo($b)'), 'method';
    ok find_usage($obj, '$a->foo($b, $c)'), 'method, all args';
    ok find_usage($obj, '$c = Foo::Bar::foo($a, $b)'), 'function';
    ok find_usage($obj, 'Foo::Bar::foo($a, $b, $c)'), 'function, all args';
    ok all_seen($obj, 'foo'), 'all seen';
};


subtest a_bc => sub {
    my $obj = call_pp_def(foo =>
        Pars => 'a(n); [o]b(n); [o]c(n)',
    );
    ok find_usage($obj, 'foo($a, $b, $c)'), 'multi output function call, all args';
    ok find_usage($obj, '($b, $c) = foo($a)'), 'multi output function call';
    ok find_usage($obj, '($b, $c) = $a->foo'), 'multi output method call';
    ok find_usage($obj, '$a->foo($b, $c)'), 'method call, all args';
    ok all_seen($obj, 'foo'), 'all seen';
};

subtest ab_k_c => sub {
    my $obj = call_pp_def(foo =>
        Pars => 'a(n); b(n); [o]c(n)',
        OtherPars => 'int k',
        ArgOrder => [qw(a b k c)],
    );
    ok find_usage($obj, 'foo($a, $b, $k, $c)'), 'OtherPars, ArgOrder, function call, all args';
    ok find_usage($obj, '$c = $a->foo($b, $k)'), 'OtherPars, ArgOrder, method call';
    ok find_usage($obj, '$a->foo($b, $k, $c)'), 'OtherPars, ArgOrder, method call, all args';
    ok find_usage($obj, '$c = foo($a, $b, $k)'), 'OtherPars, ArgOrder, function call';
    ok all_seen($obj, 'foo'), 'all seen';
};

subtest ab_c_k => sub {
    my $obj = call_pp_def(foo =>
        Pars => 'a(n); b(n); [o]c(n)',
        OtherPars => 'int k',
    );
    ok find_usage($obj, 'foo($a, $b, $c, $k)'), 'OtherPars, function call, all args';
    ok find_usage($obj, '$c = $a->foo($b, $k)'), 'OtherPars, method call';
    ok find_usage($obj, '$a->foo($b, $c, $k)'), 'OtherPars, method call, all args';
    ok find_usage($obj, '$c = foo($a, $b, $k)'), 'OtherPars, function call';
    ok all_seen($obj, 'foo'), 'all seen';
};

subtest ab_k_cd => sub {
    my $obj = call_pp_def(foo =>
        Pars => 'a(n); b(n); [o]c(n); [o]d(n)',
        OtherPars => 'int k',
        ArgOrder => [qw(a b k c d)],
    );
    ok find_usage($obj, 'foo($a, $b, $k, $c, $d)'), 'Multi-out, OtherPars, ArgOrder, function call, all args';
    ok find_usage($obj, '($c, $d) = $a->foo($b, $k)'), 'Multi-out, OtherPars, ArgOrder, method call';
    ok find_usage($obj, '$a->foo($b, $k, $c, $d)'), 'Multi-out, OtherPars, ArgOrder, method call, all args';
    ok find_usage($obj, '($c, $d) = foo($a, $b, $k)'), 'Multi-out, OtherPars, ArgOrder, function call';
    ok all_seen($obj, 'foo'), 'all seen';
};

subtest ab_cd_k => sub {
    my $obj = call_pp_def(foo =>
        Pars => 'a(n); b(n); [o]c(n); [o]d(n)',
        OtherPars => 'int k',
    );
    ok find_usage($obj, 'foo($a, $b, $c, $d, $k)'), 'Multi-out, OtherPars, function call, all args';
    ok find_usage($obj, '($c, $d) = $a->foo($b, $k)'), 'Multi-out, OtherPars, method call';
    ok find_usage($obj, '$a->foo($b, $c, $d, $k)'), 'Multi-out, OtherPars, method call, all args';
    ok find_usage($obj, '($c, $d) = foo($a, $b, $k)'), 'Multi-out, OtherPars, function call';
    ok all_seen($obj, 'foo'), 'all seen';
};

done_testing;
