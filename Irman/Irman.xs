#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <irman.h>

MODULE = RCU::Irman   PACKAGE = RCU::Irman

PROTOTYPES: ENABLE

int
ir_init(filename = Nullch)
	char *	filename

int
ir_init_commands(rcname = Nullch, warn = 0)
	char *	rcname
        int	warn

char *
ir_default_portname()

int
ir_finish()

void
ir_free_commands()

void
_get_code()
        PPCODE:
        static unsigned char *last_code;
        unsigned char *code = ir_get_code ();

        /* irman is badly designed */
        if (!code && errno == IR_EDUPCODE)
          code = last_code;

        if (code)
          {
            char *text = ir_code_to_text (code);
            last_code = code;

            XPUSHs (sv_2mortal (newSVpv (text, 0)));
            XPUSHs (sv_2mortal (newSVpv (ir_text_to_name (text), 0)));
          }


