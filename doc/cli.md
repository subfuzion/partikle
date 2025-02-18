# CLI

The CLI runs commands. Commands might have subcommands. For example:

    ptkl foo

In this example, `ptkl` is the root command. It is the parent command of the 
`foo` subcommand.

There can be multiple levels of command nesting. For example:

    ptkl foo bar

This feature should be used sparingly (if at all) in practice.

## Command handling

- The command line is fully parsed before command execution.

- All options are applied to the runtime configuration before command execution.
  The CLI will exit with an error if:
  - An option is configured by more than one command since this is confusing and
    most likely unintentional
  - An option is not configured by any command (unrecognized option)

- If the help option (`-h`, `--help`) is set, the help message for the last
  command in the command chain is printed and the CLI exits with a normal
  status. For example, for `ptkl foo bar`, the help message for `bar` is 
  printed.

- After processing the command line and setting the runtime configuration,
  command hooks for the command chain are invoked in order from left to right
  (from the root command to the final subcommand).

- The first command line argument that does not match a command, and all 
  subsequent command line arguments, are passed as arguments to the command 
  handler.

- The command handler for the final command in the chain is invoked with
  arguments.

- If the `ptkl` command is invoked instead of a subcommand, it performs the 
  following:
  - If invoked with an argument that matches a filename, the `run` command is 
    executed
  - If invoked with an argument that matches a valid expression, the `eval` 
    command is executed
  - Otherwise, it prints a help message and exits with an error status
