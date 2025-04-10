package PDL;

use strict;
use warnings;

# set the version - this is the real location again
our $VERSION = '2.100';

=head1 NAME

PDL - the Perl Data Language

=head1 SYNOPSIS

  use PDL;
  $x = zeroes 3,3; # 3x3 matrix
  $y = $x + 0.1 * xvals($x) + 0.01 * yvals($x);
  print $y;
  print $y->slice(":,1");  # row 2
  print $diag = $y->diagonal(0,1), "\n"; # 0 and 1 are the dimensions
  $diag += 100;
  print "AFTER, y=$y";
  [
   [   0  0.1  0.2]
   [0.01 0.11 0.21]
   [0.02 0.12 0.22]
  ]
  [
   [0.01 0.11 0.21]
  ]
  [0 0.11 0.22]
  AFTER, y=
  [
   [   100    0.1    0.2]
   [  0.01 100.11   0.21]
   [  0.02   0.12 100.22]
  ]

=head1 DESCRIPTION

(For the exported PDL constructor, pdl(), see L<PDL::Core>)

PDL is the Perl Data Language, a perl extension that is designed for
scientific and bulk numeric data processing and display.  It extends
perl's syntax and includes fully vectorized, multidimensional array
handling, plus several paths for device-independent graphics output.

PDL is fast, comparable and often outperforming IDL and MATLAB in real
world applications. PDL allows large N-dimensional data sets such as large
images, spectra, etc to be stored efficiently and manipulated quickly.

=head1 VECTORIZATION

For a description of the vectorization (also called "broadcasting"), see
L<PDL::Core>.

=head1 INTERACTIVE SHELL

The PDL package includes an interactive shell. You can learn about it,
run C<perldoc perldl>, or run the shell C<perldl> and type
C<help>.

=head1 LOOKING FOR A FUNCTION?

If you want to search for a function name, you should use the PDL
shell along with the "help" or "apropos" command (to do a fuzzy search).
For example:

 pdl> apropos xval
 xlinvals        X axis values between endpoints (see xvals).
 xlogvals        X axis values logarithmicly spaced...
 xvals           Fills an ndarray with X index values...
 yvals           Fills an ndarray with Y index values. See the CAVEAT for xvals.
 zvals           Fills an ndarray with Z index values. See the CAVEAT for xvals.

To learn more about the PDL shell, see L<perldl>.

=head1 LANGUAGE DOCUMENTATION

Most PDL documentation describes the language features. The number of
PDL pages is too great to list here. The following pages offer some
guidance to help you find the documentation you need.

=over 5

=item L<PDL::FAQ>

Frequently asked questions about PDL. This page covers a lot of
questions that do not fall neatly into any of the documentation
categories.

=item L<PDL::Tutorials>

A guide to PDL's tutorial-style documentation. With topics from beginner
to advanced, these pages teach you various aspects of PDL step by step.

=item L<PDL::Modules>

A guide to PDL's module reference. Modules are organized by level
(foundation to advanced) and by category (graphics, numerical methods,
etc) to help you find the module you need as quickly as possible.

=item L<PDL::Course>

This page compiles PDL's tutorial and reference pages into a comprehensive
course that takes you from a complete beginner level to expert.

=item L<PDL::Index>

List of all available documentation, sorted alphabetically. If you
cannot find what you are looking for, try here.

=item L<PDL::DeveloperGuide>

A guide for people who want to contribute to PDL.  Contributions are
very welcome!

=back

=head1 DATA TYPES

PDL comes with support for most native numeric data types available in C.
2.027 added support for C99 complex numbers.  See
L<PDL::Core>, L<PDL::Ops> and L<PDL::Math> for details on usage and
behaviour.

=head1 MODULES

PDL includes about a dozen perl modules that form the core of the
language, plus additional modules that add further functionality.
The perl module "PDL" loads all of the core modules automatically,
making their functions available in the current perl namespace.
Some notes:

=over 5

=item Modules loaded by default

 use PDL; # Is equivalent to the following:

   use PDL::Core;
   use PDL::Ops;
   use PDL::Primitive;
   use PDL::Ufunc;
   use PDL::Basic;
   use PDL::Slices;
   use PDL::Bad;
   use PDL::MatrixOps;
   use PDL::Math;
   use PDL::IO::Misc;
   use PDL::IO::FITS;
   use PDL::IO::Pic;
   use PDL::IO::Storable;

=cut

# Main loader of standard PDL package

sub import {
  my $pkg = (caller())[0];
  eval <<"EOD";
package $pkg;
# Load the fundamental packages
use PDL::Core;
use PDL::Ops;
use PDL::Primitive;
use PDL::Ufunc;
use PDL::Basic;
use PDL::Slices;
use PDL::Bad;
use PDL::MatrixOps;
use PDL::Math;
# for TPJ compatibility
use PDL::IO::Misc;          # Misc IO (Ascii)
use PDL::IO::FITS;          # FITS IO (rfits/wfits; used by rpic/wpic too)
use PDL::IO::Pic;           # rpic/wpic
# end TPJ bit
use PDL::IO::Storable; # to avoid mysterious Storable segfaults
EOD
  die $@ if $@;
}

=item L<PDL::Lite> and L<PDL::LiteF>

These are lighter-weight alternatives to the standard PDL module.
Consider using these modules if startup time becomes an issue.

Note that L<PDL::Math> and L<PDL::MatrixOps> are
I<not> included in the L<PDL::Lite> and L<PDL::LiteF>
start-up modules.

=item Exports

C<use PDL;> exports a large number of routines into the calling
namespace.  If you want to avoid namespace pollution, you must instead
C<use PDL::Lite>, and include any additional modules explicitly.

=item L<PDL::NiceSlice>

Note that the L<PDL::NiceSlice> syntax is NOT automatically
loaded by C<use PDL;>.  If you want to use the extended slicing syntax in
a standalone script, you must also say C<use PDL::NiceSlice;>.

=back

=head1 INTERNATIONALIZATION

PDL currently does not have internationalization support for
its error messages although Perl itself does support i18n
and locales.  Some of the tests for names and strings are
specific to ASCII and English.  Please report any issues
regarding internationalization to the perldl mailing lists.

Of course, volunteers to implement this or help with the
translations would be welcome.

=head1 INSTALLATION

See L<PDL::InstallGuide> for help.

=cut

# support: use Inline with => 'PDL';
# Returns a hash containing parameters accepted by recent versions of
# Inline, to tweak compilation.  Not normally called by anyone but
# the Inline API.
sub Inline {
    require PDL::Install::Files;
    goto &PDL::Install::Files::Inline;
}

##################################################
# Rudimentary handling for multiple Perl threads #
##################################################
our $no_clone_skip_warning = 0;
sub CLONE_SKIP {
    warn <<'EOF' if !$no_clone_skip_warning;
* If you need to share PDL data across threads, use memory mapped data, or
* check out PDL::Parallel::threads, available on CPAN.
* You can silence this warning by saying `$PDL::no_clone_skip_warning = 1;'
* before you create your first thread.
EOF
    $no_clone_skip_warning = 1;
    # always return 1 to tell Perl not to clone PDL data
    return 1;
}

1;
