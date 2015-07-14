SOL_VM
============

_SOL_VM_ is a virtual machine written in Object Pascal, created as a backbone for the TERRA engine and XPC compiler projects.  

It is capable of executing code in a managed enviroment, with support for concurrent programming via message passing (inspired by the Go language).  

The instruction set is quite reduced now, but it might be expanded in the future. Current it supports 32 bit integer and float point math, and it is designed to support instructions for SIMD parallelization in the future.

TODO
----------------
* Assembler tool
* SIMD instructions
* Coroutines

