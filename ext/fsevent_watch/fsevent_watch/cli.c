#include <getopt.h>
#include "cli.h"

const char* cli_info_purpose = "A flexible command-line interface for the FSEvents API";
const char* cli_info_usage = "Usage: fsevent_watch [OPTIONS]... [PATHS]...";
const char* cli_info_help[] = {
  "  -h, --help                you're looking at it",
  "  -V, --version             print version number and exit",
  "  -s, --since-when=EventID  fire historical events since ID",
  "  -l, --latency=seconds     latency period (default='0.5')",
  "  -n, --no-defer            enable no-defer latency modifier",
  "  -r, --watch-root          watch for when the root path has changed",
  // "  -i, --ignore-self         ignore current process",
  "  -F, --file-events         provide file level event data",
  "  -f, --format=name         output format (classic, niw, \n"
  "                                           tnetstring, otnetstring)",
  0
};

static void default_args (struct cli_info* args_info)
{
  args_info->since_when_arg     = kFSEventStreamEventIdSinceNow;
  args_info->latency_arg        = 0.5;
  args_info->no_defer_flag      = false;
  args_info->watch_root_flag    = false;
  args_info->ignore_self_flag   = false;
  args_info->file_events_flag   = false;
  args_info->format_arg         = kFSEventWatchOutputFormatClassic;
}

static void cli_parser_release (struct cli_info* args_info)
{
  unsigned int i;

  for (i=0; i < args_info->inputs_num; ++i) {
    free(args_info->inputs[i]);
  }

  if (args_info->inputs_num) {
    free(args_info->inputs);
  }

  args_info->inputs_num = 0;
}

void cli_parser_init (struct cli_info* args_info)
{
  default_args(args_info);

  args_info->inputs = 0;
  args_info->inputs_num = 0;
}

void cli_parser_free (struct cli_info* args_info)
{
  cli_parser_release(args_info);
}

void cli_print_version (void)
{
  printf("%s %s\n", CLI_NAME, CLI_VERSION);
#ifdef COMPILED_AT
  printf("Compiled %s\n", COMPILED_AT);
#endif
}

void cli_print_help (void)
{
  cli_print_version();

  printf("\n%s\n", cli_info_purpose);
  printf("\n%s\n", cli_info_usage);
  printf("\n");

  int i = 0;
  while (cli_info_help[i]) {
    printf("%s\n", cli_info_help[i++]);
  }
}

int cli_parser (int argc, const char** argv, struct cli_info* args_info)
{
  static struct option longopts[] = {
    { "help",         no_argument,        NULL, 'h' },
    { "version",      no_argument,        NULL, 'V' },
    { "since-when",   required_argument,  NULL, 's' },
    { "latency",      required_argument,  NULL, 'l' },
    { "no-defer",     no_argument,        NULL, 'n' },
    { "watch-root",   no_argument,        NULL, 'r' },
    { "ignore-self",  no_argument,        NULL, 'i' },
    { "file-events",  no_argument,        NULL, 'F' },
    { "format",       required_argument,  NULL, 'f' },
    { 0, 0, 0, 0 }
  };

  const char* shortopts = "hVs:l:nriFf:";

  int c = -1;

  while ((c = getopt_long(argc, (char * const*)argv, shortopts, longopts, NULL)) != -1) {
    switch(c) {
    case 's': // since-when
      args_info->since_when_arg = strtoull(optarg, NULL, 0);
      break;
    case 'l': // latency
      args_info->latency_arg = strtod(optarg, NULL);
      break;
    case 'n': // no-defer
      args_info->no_defer_flag = true;
      break;
    case 'r': // watch-root
      args_info->watch_root_flag = true;
      break;
    case 'i': // ignore-self
      args_info->ignore_self_flag = true;
      break;
    case 'F': // file-events
      args_info->file_events_flag = true;
      break;
    case 'f': // format
      if (strcmp(optarg, "classic") == 0) {
        args_info->format_arg = kFSEventWatchOutputFormatClassic;
      } else if (strcmp(optarg, "niw") == 0) {
        args_info->format_arg = kFSEventWatchOutputFormatNIW;
      } else if (strcmp(optarg, "tnetstring") == 0) {
        args_info->format_arg = kFSEventWatchOutputFormatTNetstring;
      } else if (strcmp(optarg, "otnetstring") == 0) {
        args_info->format_arg = kFSEventWatchOutputFormatOTNetstring;
      } else {
        fprintf(stderr, "Unknown output format: %s\n", optarg);
        exit(EXIT_FAILURE);
      }
      break;
    case 'V': // version
      cli_print_version();
      exit(EXIT_SUCCESS);
      break;
    case 'h': // help
    case '?': // invalid option
    case ':': // missing argument
      cli_print_help();
      exit((c == 'h') ? EXIT_SUCCESS : EXIT_FAILURE);
      break;
    }
  }

  if (optind < argc) {
    int i = 0;
    args_info->inputs_num = (unsigned int)(argc - optind);
    args_info->inputs =
      (char**)(malloc ((args_info->inputs_num)*sizeof(char*)));
    while (optind < argc)
      if (argv[optind++] != argv[0]) {
        args_info->inputs[i++] = strdup(argv[optind-1]);
      }
  }

  return EXIT_SUCCESS;
}

