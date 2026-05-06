" Vim syntax file for .jhttp (JSON HTTP Request) files.
" Delegates entirely to Neovim's built-in JSON syntax highlighting.

if exists("b:current_syntax")
  finish
endif

runtime! syntax/json.vim

let b:current_syntax = "jhttp"
