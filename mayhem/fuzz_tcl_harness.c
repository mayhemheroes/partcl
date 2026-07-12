/* libFuzzer harness for partcl: feed the input to tcl_eval, the same code path
 * the upstream REPL (main in tcl.c) drives. TEST removes upstream's main. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define TEST
#include "../tcl.c"

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  char *buf = malloc(size + 1);
  if (buf == NULL) {
    return 0;
  }
  memcpy(buf, data, size);
  buf[size] = '\0';
  struct tcl tcl;
  tcl_init(&tcl);
  tcl_eval(&tcl, buf, size + 1);
  tcl_destroy(&tcl);
  free(buf);
  return 0;
}
