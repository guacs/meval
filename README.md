# meval

A CLI based tool for evaluating mathematical expressions.

## Installation

1. Clone the repository with:  

    `git clone https://github.com/guacs/meval.git`

2. Install the D compiler from [here](https://dlang.org/download.html) if you haven't already installed it.
3. Run the following for building and testing the application (ensure you are in the root directory of the project):  

    build => `dub build`  
    
    test => `dub test`
    
## Grammar

The grammar that is used for parsing.

```
expression -> term
term -> factor (("-" | "+") factor)*
factor -> unary (("*" | "/") unary)* 
unary -> ("+" | "-") unary | primary
primary -> NUMBER | "(" expression ")"
```

`*` => repeats zero or more times
