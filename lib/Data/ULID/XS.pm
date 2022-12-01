package Data::ULID::XS;

use strict;
use warnings;

use Exporter qw(import);
use Data::ULID qw(:all);

use Time::HiRes qw();
use Crypt::PRNG::Sober128 qw();

our @EXPORT = @Data::ULID::EXPORT;
our @EXPORT_OK = @Data::ULID::EXPORT_OK;
our %EXPORT_TAGS = %Data::ULID::EXPORT_TAGS;

our $RNG = Crypt::PRNG::Sober128->new;

require XSLoader;
XSLoader::load('Data::ULID::XS', $Data::ULID::XS::VERSION);

1;
__END__

=head1 NAME

Data::ULID::XS - XS backend for ULID generation

=head1 SYNOPSIS

  use Data::ULID::XS qw(ulid binary_ulid);

=head1 DESCRIPTION

This module replaces some parts of L<Data::ULID> that are performance-critical
with XS counterparts. Its interface should be the same as Data::ULID, but you
get free XS speedups.

B<Early release>: For now, this module just speeds up base32 encoding of C<ulid>.

B<Beta quality>: while this module works well in general cases, it may also
contain errors common to C code like memory leaks or access violations. Please
do report if you encounter any problems.

=head1 SEE ALSO

L<Data::ULID>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

