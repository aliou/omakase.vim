" omakase.vim - Simpler Rails projections.
" Location: plugin/omakase.vim
" Author:   Aliou Diallo <code@aliou.me>
" Version:  0.0.1

if exists('g:loaded_omakase') || &compatible || v:version < 700
  finish
endif

let g:loaded_omakase = 1

function! s:find_root(path) abort
  let l:root = simplify(fnamemodify(a:path, ':p:s?[\/]$??'))
  let l:previous = ''

  while l:root !=# l:previous && l:root !=# '/'
    if filereadable(l:root . '/Gemfile') && filereadable('config/environment.rb')
      return l:root
    endif
    let l:previous = l:root
    let l:root = fnamemodify(l:root, ':h')
  endwhile
endfunction

function! s:Detect(path) abort
  if !exists('b:omakase_root')
    let l:dir = s:find_root(a:path)
    if l:dir !=# ''
      let b:omakase_root = l:dir
    endif
  endif
endfunction

function! s:Setup(path) abort
  call s:Detect(a:path)
  if exists('b:omakase_root')
    " Send the Omakase autocommand to add the Rails commands.
    silent doautocmd User Omakase
  endif
endfunction

augroup omakase
  autocmd!
  autocmd BufNewFile,BufReadPost *
        \ if empty(&filetype) |
        \   call s:Setup(expand('<amatch>:p')) |
        \ endif
  autocmd FileType * call s:Setup(expand('%:p'))
  autocmd User NERDTreeInit,NERDTreeNewRoot call s:Setup(b:NERDTreeRoot.path.str())
  autocmd VimEnter * if expand('<amatch>')==''| call s:Setup(getcwd()) | endif
augroup END

let s:projections = {
      \  'Gemfile': {'alternate': 'Gemfile.lock', 'type': 'lib'},
      \  'Gemfile.lock': {'alternate': 'Gemfile'},
      \  'Rakefile': {'type': 'task'},
      \  'app/channels/*_channel.rb': {
      \    'template': ['class {camelcase|capitalize|colons}Channel < ActionCable::Channel', 'end'],
      \    'type': 'channel'
      \  },
      \  'app/controllers/*_controller.rb': {
      \    'affinity': 'controller',
      \    'template': [
      \      'class {camelcase|capitalize|colons}Controller < ApplicationController',
      \      'end'
      \    ],
      \    'type': 'controller'
      \  },
      \  'app/controllers/concerns/*.rb': {
      \    'affinity': 'controller',
      \    'template': [
      \      'module {camelcase|capitalize|colons}',
      \      '\tinclude ActiveSupport::Concern',
      \      'end'
      \    ],
      \    'type': 'controller'
      \  },
      \  'app/helpers/*_helper.rb': {
      \    'affinity': 'controller',
      \    'template': ['module {camelcase|capitalize|colons}Helper', 'end'],
      \    'type': 'helper'
      \  },
      \  'app/jobs/*_job.rb': {
      \    'affinity': 'model',
      \    'template': ['class {camelcase|capitalize|colons}Job < ApplicationJob', 'end'],
      \    'type': 'job'
      \  },
      \  'app/models/*.rb': {
      \    'affinity': 'model',
      \    'template': ['class {camelcase|capitalize|colons}', 'end'],
      \    'type': 'model'
      \  },
      \  'app/serializers/*_serializer.rb': {
      \    'template': ['class {camelcase|capitalize|colons}Serializer < ActiveModel::Serializer', 'end'],
      \    'type': 'serializer'
      \  },
      \  'db/migrate/*.rb': {
      \    'type': 'migration',
      \    'template': [
      \    ]
      \  },
      \  'config/application.rb': {'alternate': 'config/routes.rb'},
      \  'config/environment.rb': {'alternate': 'config/routes.rb'},
      \  'config/environments/*.rb': {
      \    'alternate': ['config/application.rb', 'config/environment.rb'],
      \    'type': 'environment'
      \  },
      \  'config/initializers/*.rb': {'type': 'initializer'},
      \  'config/routes.rb': {
      \    'alternate': ['config/application.rb', 'config/environment.rb'],
      \    'type': 'routes'
      \  },
      \  'gems.rb': {'alternate': 'gems.locked', 'type': 'lib'},
      \  'gems.locked': {'alternate': 'gems.rb'},
      \  'lib/*.rb': {'type': 'lib'},
      \  'lib/tasks/*.rake': {'type': 'task'}
      \}

function! s:ProjectionistDetect() abort
  call s:Detect(get(g:, 'projectionist_file', ''))

  if exists('b:omakase_root')
    " Add default projections.
    let l:projections = deepcopy(s:projections)
    call projectionist#append(b:omakase_root, l:projections)

    if exists('g:rails_projections')
      call projectionist#append(b:omakase_root, g:rails_projections)
    endif
  endif
endfunction

augroup omakase_projectionist
  autocmd!
  autocmd User ProjectionistDetect call s:ProjectionistDetect()
augroup END
