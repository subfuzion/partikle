/*
 * ptkl command line args
 *
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
#ifndef ARGS_H
#define ARGS_H

#include "quickjs.h"

enum ptkl_option_type {
	OPT_STRING,
	OPT_BOOL,
	OPT_INT,
};

struct ptkl_option {
	const char *short_opt;
	const char *long_opt;
	const char *help;
	bool multi;

	enum ptkl_option_type type;

	union {
		const char *string;
		bool boolean;
		int integer;
	};

	char *str;

	void (*handler)(struct ptkl_option *opt);

	struct ptkl_option *next;
};

struct ptkl_cli {
	char *version;
	char *help;
	struct ptkl_option *options;
};

void ptkl_add_option(struct ptkl_cli *cli, struct ptkl_option *opt);

void ptkl_print_help(struct ptkl_cli *cli);

struct cliconfig {
	int argc;
	char **argv;

	const char *version;
	const char *usage;

	JSRuntime *js_runtime;
	JSContext *js_context;

	void (*initializer)(struct cliconfig *config);

	void (*finalizer)(struct cliconfig *config);
};

void run(struct cliconfig *config);

struct cli;

typedef void (*cli_fn)(struct cli *cli);

typedef void (*cli_exit_fn)(struct cli *cli);

struct cli {
	struct cliconfig *config;

	int exit_status;

	cli_fn start;
	cli_exit_fn stop;
	cli_exit_fn help;
	cli_exit_fn version;

	cli_fn onsuccess;
	cli_fn onfailure;
};

struct common_opts {
};

struct runtime_opts {
	char *expr;
	int interactive;
	int dump_memory;
	int trace_memory;
	int empty_run;
	int module;
	int load_std;
	int dump_unhandled_promise_rejection;
	size_t memory_limit;
	char *include_list[32];
	int include_count;
	size_t stack_size;
	int bignum_ext;
};

struct compiler_opts {
};

void cli_init(struct cli *cli, struct cliconfig *config);

int parse_runtime_args(int argc, char **argv, struct runtime_opts *opts);

#endif  /* ARGS_H */
