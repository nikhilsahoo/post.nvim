function! s:DetectHttpFiletype()
  if getline(1) =~# '^\s*{' || getline(1) =~# '^\s*\[' || getline(1) =~# '^\s*"'
    setfiletype json
  else
    setfiletype http
  endif
endfunction

au BufRead,BufNewFile *.http call s:DetectHttpFiletype()
