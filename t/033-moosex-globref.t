#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
BEGIN {
    eval "use MooseX::GlobRef ()";
    plan skip_all => "MooseX::GlobRef is required for this test" if $@;
    plan tests => 10;
}
# XXX: the way the IO modules are loaded means we can't just rely on cmop to
# load these properly/:
use IO::Handle;
use IO::File;

BEGIN {
    require Moose;

    package Foo::Exporter;
    use Moose::Exporter;
    Moose::Exporter->setup_import_methods(also => ['Moose']);

    sub init_meta {
        shift;
        my %options = @_;
        Moose->init_meta(%options);
        Moose::Util::MetaRole::apply_metaclass_roles(
            for_class               => $options{for_class},
            metaclass_roles         => ['MooseX::NonMoose::Meta::Role::Class'],
            constructor_class_roles =>
                ['MooseX::NonMoose::Meta::Role::Constructor'],
            instance_metaclass_roles =>
                ['MooseX::GlobRef::Role::Meta::Instance'],
        );
        return Class::MOP::class_of($options{for_class});
    }
}

package IO::Handle::Moose;
BEGIN { Foo::Exporter->import }
extends 'IO::Handle';

has bar => (
    is => 'rw',
    isa => 'Str',
);

sub FOREIGNBUILDARGS { return }

package IO::File::Moose;
BEGIN { Foo::Exporter->import }
extends 'IO::File';

has baz => (
    is => 'rw',
    isa => 'Str',
);

sub FOREIGNBUILDARGS { return }

package main;
my $handle = IO::Handle::Moose->new(bar => 'BAR');
is($handle->bar, 'BAR', 'moose accessor works properly');
$handle->bar('RAB');
is($handle->bar, 'RAB', 'moose accessor works properly (setting)');
IO::Handle::Moose->meta->make_immutable;
$handle = IO::Handle::Moose->new(bar => 'BAR');
is($handle->bar, 'BAR', 'moose accessor works properly');
$handle->bar('RAB');
is($handle->bar, 'RAB', 'moose accessor works properly (setting)');

SKIP: {
    my $fh = IO::File::Moose->new(baz => 'BAZ');
    open $fh, "+>", undef
        or skip "couldn't open a temporary file", 4;
    is($fh->baz, 'BAZ', "accessor works");
    $fh->baz('ZAB');
    is($fh->baz, 'ZAB', "accessor works (writing)");
    $fh->print("foo\n");
    print $fh "bar\n";
    $fh->seek(0, 0);
    my $buf;
    $fh->read($buf, 8);
    is($buf, "foo\nbar\n", "filehandle still works as normal");
}
IO::File::Moose->meta->make_immutable;
SKIP: {
    my $fh = IO::File::Moose->new(baz => 'BAZ');
    open $fh, "+>", undef
        or skip "couldn't open a temporary file", 4;
    is($fh->baz, 'BAZ', "accessor works");
    $fh->baz('ZAB');
    is($fh->baz, 'ZAB', "accessor works (writing)");
    $fh->print("foo\n");
    print $fh "bar\n";
    $fh->seek(0, 0);
    my $buf;
    $fh->read($buf, 8);
    is($buf, "foo\nbar\n", "filehandle still works as normal");
}
