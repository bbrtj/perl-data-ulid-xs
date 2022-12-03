#!/usr/bin/env perl

# AUTHOR SCRIPT ONLY

use v5.10;
use strict;
use warnings;

use File::Copy qw(move);

use constant MARK => '#{%s}';

sub safe_replace_file
{
	my ($file, $lines) = @_;

	my $new_file = "$file.new";

	open my $fh, '>', $new_file
		or die "couldn't open file $new_file for writing: $!";

	foreach my $line (@{$lines}) {
		say {$fh} $line
			or die "couldn't write to $new_file";
	}

	close $fh
		or die "couldn't close $new_file: $!";

	move $new_file, $file;
}

sub generate
{
	my ($file, $mark, $lines) = @_;

	my @new_lines = do {
		open my $fh, '<', $file
			or die "couldn't open file $file for reading: $!";

		readline $fh;
	};

	my $search_mark = quotemeta sprintf MARK, $mark;
	my @at_lines;
	foreach my $line_no (0 .. $#new_lines) {
		chomp $new_lines[$line_no];

		push @at_lines, $line_no
			if $new_lines[$line_no] =~ $search_mark;
	}

	die "mark $mark was not found in $file!"
		unless @at_lines;

	foreach my $line_no (reverse @at_lines) {
		my ($indent) = $new_lines[$line_no] =~ /^(\s*)/;
		splice @new_lines, $line_no, 1, map { $indent . $_ } @{$lines};
	}

	safe_replace_file($file, \@new_lines);
	return !!1;
}

sub get_base32_encoding
{
	my sub get_shift {
		my ($by) = @_;

		return ">>$by" if $by > 0;
		return '<<' . (-1 * $by) if $by < 0;
		return '';
	}

	my @lines;

	my %masks = (
		-4 => ['0x80', 7],
		-3 => ['0xc0', 6],
		-2 => ['0xe0', 5],
		-1 => ['0xf0', 4],
		0 => ['0xf8', 3],
		1 => ['0x7c', 2],
		2 => ['0x3e', 1],
		3 => ['0x1f', 0],
		4 => ['0x0f', -1],
		5 => ['0x07', -2],
		6 => ['0x03', -3],
		7 => ['0x01', -4],
	);

	my $line_proto = q{result[%d] = base32[%s];};
	my $bit_manip_proto = q{((str[%d] & %s)%s)};
	my @sizes = (6, 10);
	my $byte_char = 0;
	my $ulid_char = 0;

	foreach my $size (@sizes) {
		my $offset = $size * 8 % 5;
		$offset = -1 * (5 - $offset) if $offset;
		my $total = ($size * 8 - $offset) / 5;

		for (1 .. $total) {
			my ($mask, $shift) = @{$masks{$offset}};

			my $manip = sprintf $bit_manip_proto, $byte_char, $mask, get_shift($shift);

			$byte_char += 1
				if $shift <= 0;

			if ($shift < 0) {
				$offset = -5 - $shift;
				my ($nmask, $nshift) = @{$masks{$offset}};
				$manip = sprintf "%s + %s",
					$manip,
					sprintf($bit_manip_proto, $byte_char, $nmask, get_shift($nshift))
				;
			}

			push @lines, sprintf $line_proto, $ulid_char, $manip;
			$ulid_char += 1;
			$offset = ($offset + 5) % 8;
		}

		push @lines, '';
	}

	return \@lines;
}

my $dir = shift;
die 'I need a Dist::Zilla built directory!' unless $dir;

generate "$dir/XS.xs", 'encode_ulid', get_base32_encoding;

