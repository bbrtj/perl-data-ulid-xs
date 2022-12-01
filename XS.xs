#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

// 0123456789ABCDEFGHJKMNPQRSTVWXYZ
char get_base32_char(int num)
{
	switch (num) {
		case 0: return '0'; break;
		case 1: return '1'; break;
		case 2: return '2'; break;
		case 3: return '3'; break;
		case 4: return '4'; break;
		case 5: return '5'; break;
		case 6: return '6'; break;
		case 7: return '7'; break;
		case 8: return '8'; break;
		case 9: return '9'; break;
		case 10: return 'A'; break;
		case 11: return 'B'; break;
		case 12: return 'C'; break;
		case 13: return 'D'; break;
		case 14: return 'E'; break;
		case 15: return 'F'; break;
		case 16: return 'G'; break;
		case 17: return 'H'; break;
		case 18: return 'J'; break;
		case 19: return 'K'; break;
		case 20: return 'M'; break;
		case 21: return 'N'; break;
		case 22: return 'P'; break;
		case 23: return 'Q'; break;
		case 24: return 'R'; break;
		case 25: return 'S'; break;
		case 26: return 'T'; break;
		case 27: return 'V'; break;
		case 28: return 'W'; break;
		case 29: return 'X'; break;
		case 30: return 'Y'; break;
		case 31: return 'Z'; break;
		default:
			croak("something went wrong during encoding (tried to encode %d)", num);
	}
}

int char_to_num(char c, int pos)
{
	int mask;

	switch (pos) {
		case -4: mask = 0x80; break;
		case -3: mask = 0xc0; break;
		case -2: mask = 0xe0; break;
		case -1: mask = 0xf0; break;
		case 0: mask = 0xf8; break;
		case 1: mask = 0x7c; break;
		case 2: mask = 0x3e; break;
		case 3: mask = 0x1f; break;
		case 4: mask = 0x0f; break;
		case 5: mask = 0x07; break;
		case 6: mask = 0x03; break;
		case 7: mask = 0x01; break;
		default:
			croak("invalid padding in char_to_num: %d", pos);
	}

	int num = c & mask;
	if (pos < 3) {
		return num >> (3 - pos);
	}
	else {
		return num << (pos - 3);
	}
}

SV* encode_base32(SV *svstr)
{
	char* str = SvPVbyte_nolen(svstr);

	size_t len = strlen(str);
	int pad = (len * 8) % 5;
	size_t result_len = len * 8 / 5 + (pad > 0);

	char *result = malloc(result_len * sizeof *result + 1);
	result[result_len] = '\0';
	char *current = result;

	int last_pos = -1 * (5 - pad) % 5;
	int i;
	int num = 0;

	for (i = 0; i < len; ++i) {
		while (last_pos < 8) {
			num += char_to_num(str[i], last_pos);
			last_pos += 5;

			if (last_pos <= 8) {
				*current = get_base32_char(num);
				++current;
				num = 0;
			}
		}

		last_pos = (last_pos > 8) * (last_pos - 8 - 5);
	}

	SV *svresult = newSVpv(result, result_len);
	return svresult;
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
			int count = call_pv("Data::ULID::binary_ulid", G_SCALAR);

			SPAGAIN;

			if (count != 1) {
				croak("Calling Data::ULID::XS::binary_ulid went wrong in Data::ULID::XS::ulid");
			}

			SV *ret = POPs;
			SV *encoded = encode_base32(ret);
			SvREFCNT_inc(encoded);
			RETVAL = encoded;
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

#ifdef NOT_IMPLEMENTED

SV*
binary_ulid(...)
	CODE:
		dSP;

		PUSHMARK(SP);

		if (items == 0) {
			EXTEND(SP, 1);
			PUSHs(ST(0));
			PUTBACK;

			int count = call_pv("Data::ULID::binary_ulid", G_SCALAR);

			SPAGAIN;

			if (count != 1) {
				croak("Calling Data::ULID::binary_ulid went wrong in Data::ULID::XS::binary_ulid");
			}

			SV *bytes = POPs;
			RETVAL = newSVpv("aoeui", 4);
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

#endif

