/*
 * ptkl command line args
 *
 * Copyright (c) 2017-2024 Fabrice Bellard
 * Copyright (c) 2017-2024 Charlie Gordon
 * Copyright (c) 2025 Tony Pujals
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ptklcli.h"
#include "cutils.h"

////////////////////////////////////////////////////////////////////////////////

void help(const int exit_code) {
	printf("Partikle Runtime (version " CONFIG_VERSION ")\n"
		"usage: " PTKL " [options] [file [args]]\n"
		"-e  --eval EXPR            evaluate EXPR\n"
		"-v  --version              print version\n"
		"-h  --help                 show this help\n"
		//
		// hidden options:
		//
		//           "-m  --module               load as ES6 module (default=autodetect)\n"
		//           "    --script               load as ES6 script (default=autodetect)\n"
		//           "-I  --include file         include an additional file\n"
		//           "    --std                  make 'std' and 'os' available to the loaded script\n"
		//           "    --bignum               enable the bignum extensions (BigFloat, BigDecimal)\n"
		//           "-T  --trace                trace memory allocation\n"
		//           "-d  --dump                 dump the memory usage stats\n"
		//           "    --memory-limit n       limit the memory usage to 'n' bytes\n"
		//           "    --stack-size n         limit the stack size to 'n' bytes\n"
		//           "    --unhandled-rejection  dump unhandled promise rejections\n"
		//           "-q  --quit                 just instantiate the interpreter and quit\n"
		//
	);
	exit(exit_code);
}


////////////////////////////////////////////////////////////////////////////////

void version() {
	printf("%s %s\n", PTKL, CONFIG_VERSION);
	exit(0);
}


////////////////////////////////////////////////////////////////////////////////

// Don't use getopt so we can pass command line to scripts
int parse_runtime_args(const int argc, char **argv, struct runtime_opts *opts) {
	opts->expr = nullptr;
	opts->interactive = 0;
	opts->dump_memory = 0;
	opts->trace_memory = 0;
	opts->empty_run = 0;
	// TODO: can't make module the default yet due to tests/test_closure.js::test_with()
	opts->module = -1;
	opts->load_std = 1; // 0
	opts->dump_unhandled_promise_rejection = 0;
	opts->memory_limit = 0;
	opts->include_count = 0;
	opts->stack_size = 0;
	opts->bignum_ext = 0;

	int optind = 1;
	while (optind < argc && *argv[optind] == '-') {
		char *arg = argv[optind] + 1;
		const char *longopt = "";
		// A single - is not an option, it also stops argument scanning
		if (!*arg)
			break;
		optind++;
		if (*arg == '-') {
			longopt = arg + 1;
			arg += strlen(arg);
			// -- stops argument scanning
			if (!*longopt)
				break;
		}
		for (; *arg || *longopt; longopt = "") {
			const char opt = *arg;
			if (opt)
				arg++;
			if (opt == 'h' || opt == '?' || !
				strcmp(longopt, "help")) {
				help(0);
				continue;
			}
			if (opt == 'e' || !strcmp(longopt, "eval")) {
				if (*arg) {
					opts->expr = arg;
					break;
				}
				if (optind < argc) {
					opts->expr = argv[optind++];
					break;
				}
				fprintf(
					stderr,
					"%s: missing expression for -e\n",
					PTKL);
				exit(1);
			}
			if (opt == 'I' || !strcmp(longopt, "include")) {
				if (optind >= argc) {
					fprintf(stderr, "expecting filename");
					exit(1);
				}
				if (opts->include_count >= countof(
						opts->include_list)) {
					fprintf(
						stderr,
						"too many included files");
					exit(1);
				}
				opts->include_list[opts->include_count++] = argv
						[optind++];
				continue;
			}
			if (opt == 'm' || !strcmp(longopt, "module")) {
				opts->module = 1;
				continue;
			}
			if (!strcmp(longopt, "script")) {
				opts->module = 0;
				continue;
			}
			if (opt == 'd' || !strcmp(longopt, "dump")) {
				opts->dump_memory++;
				continue;
			}
			if (opt == 'T' || !strcmp(longopt, "trace")) {
				opts->trace_memory++;
				continue;
			}
			if (!strcmp(longopt, "std")) {
				opts->load_std = 1;
				continue;
			}
			if (!strcmp(longopt, "unhandled-rejection")) {
				opts->dump_unhandled_promise_rejection = 1;
				continue;
			}
			if (!strcmp(longopt, "bignum")) {
				opts->bignum_ext = 1;
				continue;
			}
			if (opt == 'q' || !strcmp(longopt, "quit")) {
				opts->empty_run++;
				continue;
			}
			if (!strcmp(longopt, "memory-limit")) {
				if (optind >= argc) {
					fprintf(
						stderr,
						"expecting memory limit");
					exit(1);
				}
				opts->memory_limit = (size_t) strtod(
					argv[optind++], nullptr);
				continue;
			}
			if (!strcmp(longopt, "stack-size")) {
				if (optind >= argc) {
					fprintf(stderr, "expecting stack size");
					exit(1);
				}
				opts->stack_size = (size_t) strtod(
					argv[optind++], nullptr);
				continue;
			}
			if (opt == 'v' || !strcmp(longopt, "version")) {
				version();
			}
			if (opt) {
				fprintf(stderr, "%s: unknown option '-%c'\n",
						PTKL, opt);
			} else {
				fprintf(stderr, "%s: unknown option '--%s'\n",
						PTKL, longopt);
			}
			help(1);
		}
	}
	return optind;
}


////////////////////////////////////////////////////////////////////////////////

void cli_start(struct cli *cli) {
	printf("start\n");
	cli->version(cli);
	cli->onfailure(cli);
}


void cli_stop(struct cli *cli) {
	if (!cli->exit_status) cli->exit_status = 1;
	fprintf(stderr, "stop (exit status: %d)\n", cli->exit_status);
	exit(cli->exit_status);
}


void cli_help(struct cli *cli) {
	printf("help\n");
	cli->stop(cli);
}


void cli_version(struct cli *cli) {
	printf("version\n");
	cli->stop(cli);
}


void cli_onsuccess(struct cli *cli) {
	printf("onsuccess\n");
	cli->stop(cli);
}


void cli_onfailure(struct cli *cli) {
	printf("onfailure\n");
	cli->stop(cli);
}


void cli_init(struct cli *cli, struct cliconfig *config) {
	cli->config = config;
	cli->start = cli_start;
	cli->stop = cli_stop;
	cli->help = cli_help;
	cli->version = cli_version;
	cli->onsuccess = cli_onsuccess;
	cli->onfailure = cli_onfailure;
}


////////////////////////////////////////////////////////////////////////////////

void run(struct cliconfig *config) {
	struct cli cli = {};
	cli_init(&cli, config);
	cli.start(&cli);
}


////////////////////////////////////////////////////////////////////////////////
/// Help

#define COLUMN_SEP "  "


static void print_option_help(const struct ptkl_option *opt,
							  const unsigned max_field_width) {
	printf(COLUMN_SEP "-%s"
		   COLUMN_SEP "--%-*s"
		   COLUMN_SEP "%s"
		   "\n",
		   opt->short_opt, max_field_width - 4, opt->long_opt, opt->help
	);
}


static void print_subcommand_help(const struct ptkl_command *cmd,
							   const unsigned max_field_width) {
	printf(COLUMN_SEP "%-*s"
		   COLUMN_SEP "%-s"
		   "\n",
		   max_field_width + 2, cmd->usage, cmd->help
	);
}


static unsigned min(const unsigned a, const unsigned b) {
	return a < b ? a : b;
}


// Updates the command's `usage` field.
//
// The usage string is formatted based on the command's name and args fields.
// If the total length of the usage string would be longer than the field's
// capacity, then a single set of ellipses ("...") is appended instead of a
// series of formatted args.
//
// The caller must ensure the following:
//
// 1. cmd->usage points to a character buffer large
//    enough for a formatted usage string (based on cmd->name and cmd->args).
//
// 2. size is the total length of the allocated buffer (including space for a
// null terminator ('\0)).
//
static void cmdusage(const struct ptkl_command *cmd, const unsigned size) {
	const unsigned cap = size - 1;
	unsigned len = 0;
	char *usage = cmd->usage;
	memset(usage, 0, sizeof(char) * size);
	strncpy(usage, cmd->name, cap - len);
	len += strlen(cmd->name);
	const struct ptkl_arg *arg = cmd->args;
	while (arg && len < cap) {
		strcat(usage, " ");
		++len;
		if (len < cap) {
			strcat(usage, arg->optional ? "[" : "<");
			++len;
		}
		unsigned m = min(1 + strlen(arg->name), cap - len);
		strncat(usage, arg->name, m);
		len += m;
		if (len < cap) {
			strcat(usage, arg->optional ? "]" : ">");
			++len;
		}
		arg = arg->next;
	}
	if (len >= cap) {
		memset(usage, 0, sizeof(char) * size);
		sprintf(usage, "%*s ...", min(cap - 4, strlen(cmd->name)), cmd->name);
	}
}


static void print_command_help(const struct ptkl_command *cmd) {
	if (cmd->help) {
		printf("%s\n", cmd->help);
	}

	// Field width to ensure gap before printing the help column.
	// The initial value is the minimum width for an aesthetic appearance.
	// The same value is used for aligning both option and command help.
	unsigned longest_field_width = 10; {

		// Determine max column width for long options
		const struct ptkl_option *opt = cmd->options;
		while (opt) {
			const unsigned width = strlen(opt->long_opt);
			if (width > longest_field_width) longest_field_width = width;
			opt = opt->next;
		}

		// Compute command usage strings and determine max column width
		struct ptkl_command *subcmd = cmd->subcommand;
		while (subcmd) {
			const unsigned cap = 32;
			subcmd->usage = (char *) calloc(cap + 1, sizeof(char));
			cmdusage(subcmd, cap);
			const unsigned width = strlen(subcmd->usage);
			if (width > longest_field_width) longest_field_width = width;
			subcmd = subcmd->next;
		}
	}

	printf("\nOptions:\n"); {
		const struct ptkl_option *opt = cmd->options;
		while (opt) {
			print_option_help(opt, longest_field_width);
			opt = opt->next;
		}
	}

	printf("\nCommands:\n"); {
		const struct ptkl_command *subcmd = cmd->subcommand;
		while (subcmd) {
			print_subcommand_help(subcmd, longest_field_width);
			subcmd = subcmd->next;
		}
	}
}


// hidden options:
//
//           "-m  --module               load as ES6 module (default=autodetect)\n"
//           "    --script               load as ES6 script (default=autodetect)\n"
//           "-I  --include file         include an additional file\n"
//           "    --std                  make 'std' and 'os' available to the loaded script\n"
//           "    --bignum               enable the bignum extensions (BigFloat, BigDecimal)\n"
//           "-T  --trace                trace memory allocation\n"
//           "-d  --dump                 dump the memory usage stats\n"
//           "    --memory-limit n       limit the memory usage to 'n' bytes\n"
//           "    --stack-size n         limit the stack size to 'n' bytes\n"
//           "    --unhandled-rejection  dump unhandled promise rejections\n"
//           "-q  --quit                 just instantiate the interpreter and quit\n"
//
void ptkl_cli_help(const struct ptkl_cli *cli) {
	const struct ptkl_command *root_cmd = cli->command;

	printf("Partikle Runtime (version %s)\n\n", cli->version);

	print_command_help(root_cmd);
}


////////////////////////////////////////////////////////////////////////////////
/// Commands

void ptkl_command_add_arg(struct ptkl_command *cmd, struct ptkl_arg *arg) {
	if (!cmd->args) {
		cmd->args = arg;
		return;
	}
	struct ptkl_arg *a = cmd->args;
	while (a->next) {
		a = a->next;
	}
	a->next = arg;
}


void ptkl_command_add_option(struct ptkl_command *cmd,
							 struct ptkl_option *opt) {
	if (!cmd->options) {
		cmd->options = opt;
		return;
	}
	struct ptkl_option *o = cmd->options;
	while (o->next) {
		o = o->next;
	}
	o->next = opt;
}


void ptkl_command_add_subcommand(struct ptkl_command *cmd,
								 struct ptkl_command *subcommand) {
	if (!cmd->subcommand) {
		cmd->subcommand = subcommand;
		return;
	}
	struct ptkl_command *c = cmd->subcommand;
	while (c->next) {
		c = c->next;
	}
	c->next = subcommand;
}
