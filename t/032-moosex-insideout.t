#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
BEGIN {
    eval "use MooseX::InsideOut ()";
    plan skip_all => "MooseX::InsideOut is required for this test" if $@;
    plan tests => 2;
}

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
                ['MooseX::InsideOut::Role::Meta::Instance'],
        );
        return Class::MOP::class_of($options{for_class});
    }
}

package Foo;

sub new {
    my $class = shift;
    bless [$_[0]], $class;
}

sub foo {
    my $self = shift;
    $self->[0] = shift if @_;
    $self->[0];
}

package Foo::Moose;
BEGIN { Foo::Exporter->import }
extends 'Foo';

has bar => (
    is => 'rw',
    isa => 'Str',
);

sub BUILDARGS {
    my $self = shift;
    shift;
    return $self->SUPER::BUILDARGS(@_);
}

package main;
my $foo = Foo::Moose->new('FOO', bar => 'BAR');
is($foo->foo, 'FOO', 'base class accessor works');
is($foo->bar, 'BAR', 'subclass accessor works');