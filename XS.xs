#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define ULID_LEN 16
#define ULID_TIME_LEN 6
#define ULID_RAND_LEN 10
#define RESULT_LEN 26

SV* encode_ulid(SV *strsv)
{
	unsigned long len;
	char *str = SvPVbyte(strsv, len);
	if (len != ULID_LEN) croak("invalid string length in encode_ulid: %d", len);

	char base32[] = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
	char result[RESULT_LEN];

	// This part will be replaced with a pregenerated base32 encoding for
	// ULIDs, which runs significantly faster. See gen/gen_streamlined_ulid.pl
	// script for details.

	// autogenerated:
	// #{encode_ulid}

	return newSVpv(result, RESULT_LEN);
}

SV* build_binary_ulid (double time, SV *randomnesssv)
{
	unsigned long len;
	char *randomness = SvPVbyte(randomnesssv, len);
	if (len == 0) croak("no randomness was fetched for build_binary_ulid");

	char result[ULID_LEN] = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";
	int i, j;

	unsigned long long microtime = time * 1000;

	// network byte order
	for (i = ULID_TIME_LEN - 1; i >= 0; --i) {
		result[i] = (char) (microtime & 0xff);
		microtime = microtime >> 8;
	}

	for (i = ULID_LEN - len, j = 0; i < ULID_LEN; ++i) {
		result[i] = randomness[j++];
	}

	return newSVpv(result, ULID_LEN);
}

// proper XS Code starts here

MODULE = Data::ULID::XS		PACKAGE = Data::ULID::XS

PROTOTYPES: DISABLE

SV*
ulid(...)
	CODE:
		dSP;

		PUSHMARK(SP);

		if (items == 0) {
			int count = call_pv("Data::ULID::XS::binary_ulid", G_SCALAR);

			SPAGAIN;

			if (count != 1) {
				croak("Calling Data::ULID::XS::binary_ulid went wrong in Data::ULID::XS::ulid");
			}

			RETVAL = encode_ulid(POPs);
		}
		else {
			EXTEND(SP, 1);
			PUSHs(ST(0));
			PUTBACK;

			int count = call_pv("Data::ULID::ulid", G_SCALAR);

			SPAGAIN;

			if (count != 1) {
				croak("Calling Data::ULID::ulid went wrong in Data::ULID::XS::ulid");
			}

			SV *ret = POPs;
			SvREFCNT_inc(ret);
			RETVAL = ret;
		}

		PUTBACK;
	OUTPUT:
		RETVAL

SV*
binary_ulid(...)
	CODE:
		dSP;

		PUSHMARK(SP);

		if (items == 0) {
			SV *tmp = newSViv(10);

			EXTEND(SP, 2);
			PUSHs(get_sv("Data::ULID::XS::RNG", 0));
			PUSHs(tmp);
			PUTBACK;

			int count = call_method("bytes", G_SCALAR);
			SvREFCNT_dec(tmp);

			SPAGAIN;

			if (count != 1) {
				croak("Calling method bytes on Crypt::PRNG::* went wrong in Data::ULID::XS::binary_ulid");
			}

			SV **svp = hv_fetchs(PL_modglobal, "Time::NVtime", 0);
			if (!SvIOK(*svp)) croak("Time::NVtime isn't a function pointer");
			NV (*nvtime)() = INT2PTR(NV(*)(), SvIV(*svp));

			RETVAL = build_binary_ulid((*nvtime)(), POPs);
		}
		else {
			EXTEND(SP, 1);
			PUSHs(ST(0));
			PUTBACK;

			int count = call_pv("Data::ULID::binary_ulid", G_SCALAR);

			SPAGAIN;

			if (count != 1) {
				croak("Calling Data::ULID::binary_ulid went wrong in Data::ULID::XS::binary_ulid");
			}

			SV *ret = POPs;
			SvREFCNT_inc(ret);
			RETVAL = ret;
		}

		PUTBACK;
	OUTPUT:
		RETVAL

