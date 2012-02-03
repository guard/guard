#ifndef CLI_H
#define CLI_H

#ifndef CLI_NAME
#define CLI_NAME "fsevent_watch"
#endif /* CLI_NAME */

#ifndef PROJECT_VERSION
#error "PROJECT_VERSION not set"
#endif /* PROJECT_VERSION */

#ifndef CLI_VERSION
#define _str(s) #s
#define _xstr(s) _str(s)
#define CLI_VERSION _xstr(PROJECT_VERSION)
#endif /* CLI_VERSION */

#include "common.h"

struct cli_info {
  UInt64 since_when_arg;
  double latency_arg;
  bool no_defer_flag;
  bool watch_root_flag;
  bool ignore_self_flag;
  bool file_events_flag;
  enum FSEventWatchOutputFormat format_arg;

  char** inputs;
  unsigned inputs_num;
};

extern const char* cli_info_purpose;
extern const char* cli_info_usage;
extern const char* cli_info_help[];

void cli_print_help(void);
void cli_print_version(void);

int cli_parser (int argc, const char** argv, struct cli_info* args_info);
void cli_parser_init (struct cli_info* args_info);
void cli_parser_free (struct cli_info* args_info);


#endif /* CLI_H */
