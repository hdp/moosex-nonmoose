#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 9;

package Foo;

sub new {
    my $class = shift;
    bless { _class => $class }, $class;
}

package Foo::Moose;
use Moose;
use MooseX::NonMoose;
extends 'Foo';

package main;
my $foo = Foo->new;
my $foo_moose = Foo::Moose->new;
isa_ok($foo, 'Foo');
is($foo->{_class}, 'Foo', 'Foo gets the correct class');
isa_ok($foo_moose, 'Foo::Moose');
isa_ok($foo_moose, 'Foo');
isa_ok($foo_moose, 'Moose::Object');
is($foo_moose->{_class}, 'Foo::Moose', 'Foo::Moose gets the correct class');
my $meta = Foo::Moose->meta;
ok($meta->has_method('new'), 'Foo::Moose has its own constructor');
my $cc_meta = $meta->constructor_class->meta;
isa_ok($cc_meta, 'Moose::Meta::Class');
ok($cc_meta->does_role('MooseX::NonMoose::Meta::Role::Constructor'),
   'Foo::Moose gets its constructor from MooseX::NonMoose');
