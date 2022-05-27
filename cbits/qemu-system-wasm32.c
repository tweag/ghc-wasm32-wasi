#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
  char *cwd = get_current_dir_name();
  size_t wasmtime_pwd_arg_len = 4 + strlen(cwd) + 1;
  char *wasmtime_pwd_arg = malloc(wasmtime_pwd_arg_len);
  snprintf(wasmtime_pwd_arg, wasmtime_pwd_arg_len, "PWD=%s", cwd);

  char *wasmtime_argv_init[] = {WASMTIME,         "run",      "--disable-cache",
                                "--env",          "PATH=",    "--env",
                                wasmtime_pwd_arg, "--mapdir", "/::/"};
  int wasmtime_argv_init_length = (sizeof(wasmtime_argv_init) / sizeof(char *));

  char *wasmtime_argv[wasmtime_argv_init_length + argc];

  for (int i = 0; i < wasmtime_argv_init_length; ++i) {
    wasmtime_argv[i] = wasmtime_argv_init[i];
  }
  for (int i = 5; i <= argc; ++i) {
    wasmtime_argv[wasmtime_argv_init_length + i - 5] = argv[i];
  }

  return execv(WASMTIME, wasmtime_argv);
}
