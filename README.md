# Partikle Runtime

## Overview

This project is a fork of [QuickJS], an embeddable JavaScript engine, 
created by Fabrice Bellard.

The purpose of this fork is to support a lightweight JavaScript runtime and 
standard library for modern web apps.

Changes in this fork include:

* Update for C23; streamline (strip features that aren't needed, such as 
  Windows and 32-bit support); remove bigfloat, bigdecimal, and qjscalc
* Implement standard library for web APIs (like `fetch`), web request handlers, 
  and distributed app internal service messaging
* Add automatic type-stripping for JavaScript + types
* Build all-in-one executable that includes
  * JavaScript engine and compiler
  * Storage engine
  * Database engine
  * Messaging engine
  * Command, monitor, and administration shell

[QuickJS]: https://bellard.org/quickjs
