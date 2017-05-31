# ABSTRACT: parent class for subclassing PDL 2.X from class frameworks
package PDLx::DetachedObject;

use strict;
use warnings;

our $VERSION = '0.02';

our @ISA = qw( PDL );
use PDL::Lite;

=begin pod_coverage

=head3 initialize

=head3 new

=end pod_coverage

=cut

sub initialize { return PDL->null }

sub new {
    my $class = shift;
    bless { PDL => PDL->null }, $class;
}

1;

# COPYRIGHT

__END__


=pod

=head1 SYNOPSIS

=head3 Moo

   # DEPRECATED; use MooX::PDL2 instead
   package MyPDL;

   use Moo;
   use PDL::Lite;

   extends 'PDLx::DetachedObject';

   has PDL => ( is => 'rw' );


=head3 Class::Tiny

    package MyPDL;

    use Class::Tiny qw[ PDL ];

    use parent 'PDLx::DetachedObject';

=head3 Object::Tiny

    package MyPDL;

    use Object::Tiny qw[ PDL ];

    use parent 'PDLx::DetachedObject';

=head3 Class::Accessor

    package MyPDL;

    use parent 'Class::Accessor', 'PDLx::DetachedObject';
    __PACKAGE__->follow_best_practice;
    __PACKAGE__->mk_accessors( 'PDL' );

or with Antlers:

    package MyPDL;
    use Class::Accessor "antlers";
    use parent 'PDLx::DetachedObject';

    has PDL => ( is => 'ro' );



=head1 DESCRIPTION

B<PDLx::DetachedObject> provides a minimal shim between L<PDL> and
object-orientation frameworks.  Directly subclassing B<PDL> is tricky,
as a B<PDL> object (a piddle) is a blessed scalar, not a blessed hash.
B<PDL> provides an L<alternate|PDL::Objects> means of subclassing; this
class encapsulates that prescription.

For L<Moo> based classes, see L<MooX::PDL2>, which provides a more
integrated approach.

=head2 Background

Because a B<PDL> object is a blessed scalar, outside of using
inside-out classes as the subclass, there is no easy means of adding
extra attributes to the object.

To work around this, B<PDL> will treat any hash blessed into a
subclass of PDL which has an entry with key C<PDL> whose value is a
real B<PDL> object as a B<PDL> object.

So far, here's a L<< B<Moo> >> version of the class

   package MyPDL;

   use Moo;

   extends 'PDL';

   # don't pass any constructor arguments to PDL->new; it confuses it
   sub FOREIGNBUILDARGS {}

   has PDL => ( is => 'rw' );
   has required_attr => ( is => 'ro', required =>1 );

When B<PDL> needs to instantiate an object from the subclass,
it doesn't call the subclass's constructor, rather it calls the
B<initialize> class method, which is expected to return a hash,
blessed into the subclass, containing the C<PDL> key as well as any
other attributes.

  sub initialize {
    my $class = shift;
    bless { PDL => PDL->null }, $class;
  }

The B<initialize> method is invoked in a variety of places.  For
instance, it's called in B<PDL::new>, which due to B<Moo>'s
inheritance scheme will be called by B<MyPDL>'s constructor:

  $mypdl = MyPDL->new( required_attr => 2 );

It's also called when B<PDL> needs to create an object to receive
the results of a B<PDL> operation on a B<MyPDL> object:

  $newpdl = $mypdl + 1;

There's one wrinkle, however.  B<PDL> I<must> create an object without
any extra attributes (it cannot know which values to give them) so
B<initialize()> is called with a I<single> argument, the class name.
This means that C<$newpdl> will be an I<incomplete> B<MyPDL> object,
i.e.  C<required_attr> is uninitialized. This can I<really> confuse
polymorphic code which operates differently when handed a B<PDL> or
B<MyPDL> object.

One way out of this dilemma is to have B<PDL> create a I<normal> piddle
instead of a B<MyPDL> object.  B<MyPDL> has explicitly indicated it wants to be
treated as a normal piddle in B<PDL> operations (by subclassing from B<PDL>) so
this doesn't break that contract.

  $newpdl = $mypdl + 1;

would result in C<$newpdl> being a normal B<PDL> object, not a B<MyPDL>
object.

Subclassing from B<PDLx::DetachedObject> effects this
behavior. B<PDLx::DetachedObject> provides a wrapper constructor and
an B<initialize> class method.  The constructor ensures returns a
properly subclassed hash with the C<PDL> key, keeping B<PDL> happy.
When B<PDL> calls the B<initialize> function it gets a normal B<PDL>.

=head2 Classes without required constructor parameters

If your class does I<not> require parameters be passed to the constructor,
it is safe to overload the C<initialize> method to return a fully fledged
instance of your class:

 sub initialize { shift->new() }

=head2 Using with Class Frameworks

The L</SYNOPSIS> shows how to use B<PDLx::DetachedObject> with various
class frameworks.  The key differentiation between frameworks is
whether or not they will call a superclass's constructor.  B<Moo>
always calls it, B<Class::Tiny> calls it only if it inherits from
B<Class::Tiny::Object>, and B<Object::Tiny> and B<Class::Accessor>
never will call the superclass' constructor.

=head1 BUGS AND LIMITATIONS


Please report any bugs or feature requests to
C<bug-pdlx-detachedobject@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=PDLx-DetachedObject>.

=cut
