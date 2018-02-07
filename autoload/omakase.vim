" Debug: Dump projections into a file.
function! omakase#dump_projections() abort
  let l:projections = json_encode(b:projectionist)
  call writefile([l:projections], 'omakase_vim_projections.json')
endfunction
