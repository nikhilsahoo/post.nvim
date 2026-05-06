" Vim syntax file for .http (REST Client) files
" Language: HTTP Request (.http)

if exists("b:current_syntax")
  finish
endif

" Comments
syn match httpComment "^#.*$" contains=@Spell
syn match httpComment "^//.*$" contains=@Spell

" Request delimiter
syn match httpDelimiter "^###\+$"

" Template variables (work in both text and JSON)
syn match httpVariable "{{[[:alnum:]_]\+}}"

" JSON body - full file or embedded. Use keepend so we don't spill over.
syn region httpJson matchgroup=NONE start="^\s*{" end="^\s*}" keepend extend fold
syn region httpJson matchgroup=NONE start="^\s*\[" end="^\s*\]" keepend extend fold

if has("conceal")
  syn region httpJsonString contained containedin=httpJson matchgroup=jsonQuote start=/"/ skip=/\\"/ end=/"/
  syn match httpJsonNumber contained containedin=httpJson "\<[0-9.]\+\>"
  syn match httpJsonBoolean contained containedin=httpJson "\<true\>\|\<false\>"
  syn match httpJsonNull contained containedin=httpJson "\<null\>"
  syn match httpJsonKey contained containedin=httpJson "\"[\w_]\+\"\ze\s*:"
else
  syn region httpJsonString contained containedin=httpJson start=/"/ skip=/\\"/ end=/"/
  syn match httpJsonNumber contained containedin=httpJson "\I\<[0-9.]\+\>"
  syn match httpJsonBoolean contained containedin=httpJson "\I\<true\>\|\<false\>\I"
  syn match httpJsonNull contained containedin=httpJson "\I\<null\>\I"
  syn match httpJsonKey contained containedin=httpJson "\"[\w_]\+\"\ze\s*:"
endif

" Text-format patterns - only match on lines that do NOT start with { [ " or }
" Check that the line is not inside a JSON body by using nextgroup/contains constraints.

" HTTP method - only at beginning of line, not inside JSON
syn match httpMethod "^GET\s"me=e-1 nextgroup=httpUrl skipwhite
syn match httpMethod "^POST\s"me=e-1 nextgroup=httpUrl skipwhite
syn match httpMethod "^PUT\s"me=e-1 nextgroup=httpUrl skipwhite
syn match httpMethod "^DELETE\s"me=e-1 nextgroup=httpUrl skipwhite
syn match httpMethod "^PATCH\s"me=e-1 nextgroup=httpUrl skipwhite
syn match httpMethod "^HEAD\s"me=e-1 nextgroup=httpUrl skipwhite
syn match httpMethod "^OPTIONS\s"me=e-1 nextgroup=httpUrl skipwhite

" URL - after method, or standalone URL line. Must not contain {{ }} boundaries.
syn match httpUrl "^[A-Z]\+[ \t]\+\zshttps\?://\S\+" contains=httpScheme
syn match httpUrl "^[A-Z]\+[ \t]\+\zs\S\+"
syn match httpScheme "https\?://" contained

" Header name - line starts with word-characters followed by colon
" But only on lines that are NOT inside a JSON region
syn match httpHeaderLine "^\s*[[:alnum:]-]\+:" contains=httpHeaderName
syn match httpHeaderName "[[:alnum:]-]\+" contained containedin=httpHeaderLine nextgroup=httpHeaderColon skipwhite
syn match httpHeaderColon ":" contained

" HTTP version (in response status lines)
syn match httpVersion "HTTP/[0-9.]\+"

" Status code
syn match httpStatusCode "\s[0-9]\{3\}\s"

" Highlight groups
hi def link httpComment           Comment
hi def link httpDelimiter         Comment
hi def link httpMethod            Keyword
hi def link httpUrl               Underlined
hi def link httpScheme            String
hi def link httpVersion           Type
hi def link httpStatusCode        Number
hi def link httpHeaderLine        Identifier
hi def link httpHeaderName        Identifier
hi def link httpHeaderColon       Delimiter
hi def link httpVariable          Special

hi def link httpJsonString        String
hi def link httpJsonNumber        Number
hi def link httpJsonBoolean       Boolean
hi def link httpJsonNull          Constant
hi def link httpJsonKey           Identifier

let b:current_syntax = "http"
