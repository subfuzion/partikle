# Partikle Runtime

## Overview

This project is a fork of [QuickJS], an embeddable JavaScript engine, 
created by Fabrice Bellard.

The purpose of this fork is to support a lightweight JavaScript runtime and 
standard library for modern web apps.

Changes in this fork include:

* Streamlining of source code (stripping features that aren't needed, such as 
  Windows and 32-bit support) and updates for C23
* Standard library for web APIs (like `fetch`), web request handlers, and 
  distributed app internal service messaging
* Automatic type-stripping for JavaScript + types
* All-in-one executable that includes
  * JavaScript compiler and JavaScript engine,
  * Storage engine
  * Database engine
  * Messaging engine
  * Shell for command, monitoring, and administration interface

[QuickJS]: https://bellard.org/quickjs
