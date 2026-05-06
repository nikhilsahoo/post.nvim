" Vim syntax file for .http (REST Client) files

if exists("b:current_syntax")
  finish
endif

" If the file is JSON, delegate to json.vim
let s:first_line = getline(1)
if s:first_line =~# '^\s*{' || s:first_line =~# '^\s*\[' || s:first_line =~# '^\s*"'
  runtime! syntax/json.vim
  let b:current_syntax = "http"
  finish
endif

" Comments
syn match httpComment "^#.*$" contains=@Spell
syn match httpComment "^//.*$" contains=@Spell

" Request delimiter
syn match httpDelimiter "^###\+$"

" Template variables
syn match httpVariable "{{[[:alnum:]_]\+}}"

" HTTP method at start of line
syn match httpMethod "^GET\s"me=e-1
syn match httpMethod "^POST\s"me=e-1
syn match httpMethod "^PUT\s"me=e-1
syn match httpMethod "^DELETE\s"me=e-1
syn match httpMethod "^PATCH\s"me=e-1
syn match httpMethod "^HEAD\s"me=e-1
syn match httpMethod "^OPTIONS\s"me=e-1

" URL after method
syn match httpUrl "^\u\+[ \t]\+\zshttps\?://\S\+" contains=httpScheme
syn match httpScheme "https\?://" contained

" Header line (word-chars followed by colon at line start)
syn match httpHeaderLine "^\s*[[:alnum:]-]\+:" contains=httpHeaderName
syn match httpHeaderName "[[:alnum:]-]\+" contained nextgroup=httpHeaderColon skipwhite
syn match httpHeaderColon ":" contained

" HTTP version (response status)
syn match httpVersion "HTTP/[0-9.]\+"
syn match httpStatusCode "\s[0-9]\{3\}\s"

" Highlight groups
hi def link httpComment           Comment
hi def link httpDelimiter         Comment
hi def link httpMethod            Keyword
hi def link httpUrl               Underlined
hi def link httpScheme            String
hi def link httpHeaderLine        Identifier
hi def link httpHeaderName        Identifier
hi def link httpHeaderColon       Delimiter
hi def link httpVariable          Special
hi def link httpVersion           Type
hi def link httpStatusCode        Number

let b:current_syntax = "http"
