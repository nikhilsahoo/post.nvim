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

" HTTP method
syn match httpMethod "^\s*\zsGET\ze\s" nextgroup=httpUrl skipwhite
syn match httpMethod "^\s*\zsPOST\ze\s" nextgroup=httpUrl skipwhite
syn match httpMethod "^\s*\zsPUT\ze\s" nextgroup=httpUrl skipwhite
syn match httpMethod "^\s*\zsDELETE\ze\s" nextgroup=httpUrl skipwhite
syn match httpMethod "^\s*\zsPATCH\ze\s" nextgroup=httpUrl skipwhite
syn match httpMethod "^\s*\zsHEAD\ze\s" nextgroup=httpUrl skipwhite
syn match httpMethod "^\s*\zsOPTIONS\ze\s" nextgroup=httpUrl skipwhite

" URL
syn match httpUrl "\S\+" contained nextgroup=httpVersion skipwhite
syn match httpUrl "^\s*\zshttps\?://\S\+" contains=httpScheme
syn match httpScheme "https\?://" contained nextgroup=httpUrlPath
syn match httpUrlPath "\S\+" contained

" HTTP version (in response status lines)
syn match httpVersion "HTTP/[0-9.]\+"

" Status code
syn match httpStatusCode "\s\d\{3\}\s"

" Header name
syn match httpHeader "^\s*\zs[[:alnum:]-]\+\(\s*:\s*\|:\)\ze" contains=httpHeaderSep
syn match httpHeaderSep ":" contained

" Variables in templates (e.g. {{base_url}}, {{token}})
syn match httpVariable "{{[[:alnum:]_]\+}}"

" JSON body region (after a blank line following headers)
syn region httpJsonBody start="^\s*{" end="^\s*}" keepend extend
syn region httpJsonBody start="^\s*\[" end="^\s*\]" keepend extend

" String values in JSON
syn match httpJsonString "\"[^\"]*\"" contained containedin=httpJsonBody

" Keys in JSON
syn match httpJsonKey "\"[\w_]\+\"\ze\s*:" contained containedin=httpJsonBody

" Numbers in JSON
syn match httpJsonNumber "\<[0-9.]\+\>" contained containedin=httpJsonBody

" Booleans and null in JSON
syn keyword httpJsonBoolean true false contained containedin=httpJsonBody
syn keyword httpJsonNull null contained containedin=httpJsonBody

" Define highlight groups
hi def link httpComment           Comment
hi def link httpDelimiter         Comment
hi def link httpMethod            Keyword
hi def link httpScheme            String
hi def link httpUrlPath           Underlined
hi def link httpUrl               Underlined
hi def link httpVersion           Type
hi def link httpStatusCode        Number
hi def link httpHeader            Identifier
hi def link httpHeaderSep         Delimiter
hi def link httpVariable          Special
hi def link httpJsonBody          String
hi def link httpJsonString        String
hi def link httpJsonKey           Identifier
hi def link httpJsonNumber        Number
hi def link httpJsonBoolean       Boolean
hi def link httpJsonNull          Constant

let b:current_syntax = "http"
