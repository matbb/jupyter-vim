"=============================================================================
"    File: ftplugin/python/jupyter_vim.vim
" Created: 07/28/11 22:14:58
"  Author: Paul Ivanov (http://pirsquared.org)
"  Updated: [11/13/2017] William Van Vliet
"  Updated: [02/14/2018, 12:31] Bernie Roesler
"
" Description: Vim integration with Jupyter Console
"
" A two-way integration between Vim and Jupyter Console and QtConsole.
"
" Using this plugin, you can send lines or whole files for IPython to execute,
" and also get back object introspection and word completions in Vim, like
" what you get with: object?<enter>, or object.<tab> in IPython
"
" This version of vim-ipython has been tested on the following:
" $ ipython --version           # 6.1.0
" $ jupyter --version           # 4.3.0
" $ jupyter console --version   # 5.2.0
" $ jupyter qtconsole --version # 4.3.1
" $ jupyter notebook --version  # 5.0.0
"
"=============================================================================

" if exists("b:loaded_jupyter") || !has('pythonx') || &cp || !has('channel')
if !has('pythonx') || !has('job') || &cp
    finish
endif

if !jupyter#init_python()
    finish
endif

"----------------------------------------------------------------------------- 
"        Configuration: {{{
"-----------------------------------------------------------------------------
" TODO set defaults via dictionary + loop like in jedi-vim
if !exists("g:jupyter_mapkeys")
    let g:jupyter_mapkeys = 1
endif

if !exists("g:jupyter_auto_connect")
    let g:jupyter_auto_connect = 1
endif

" flags for Jupyter's run file magic
if !exists('g:ipython_run_flags')
    let g:ipython_run_flags = ''
endif

if !exists('g:ipy_monitor_subchannel')
    let g:ipy_monitor_subchannel = 0
endif

"}}}-------------------------------------------------------------------------- 
"        Autocmds: {{{
"-----------------------------------------------------------------------------
augroup vim-ipython
    autocmd!
    au FileType python Jupyter
    " TODO mode this autocmd to an async process that only reports back
    " important things like tracebacks, and sends all else to the console 
    " au CursorHold *.*,vim-ipython :pythonx 
    "             \ if jupyter_vim.update_subchannel_msgs(): 
    "             \   jupyter_vim.vim_echo("vim-ipython shell updated (on idle)",'Operator')
augroup END

"}}}-------------------------------------------------------------------------- 
"        Commands: {{{
"-----------------------------------------------------------------------------
command! -buffer -nargs=0 Jupyter                  :pythonx jupyter_vim.connect_to_kernel()
command! -buffer -nargs=* JupyterInterrupt         :pythonx jupyter_vim.interrupt_kernel_hack("<args>")
command! -buffer -nargs=0 JupyterTerminate         :pythonx jupyter_vim.terminate_kernel_hack()
" command! -buffer -nargs=0 -bang JupyterInput       :pythonx InputPrompt(force='<bang>')
" command! -buffer -nargs=0 -bang JupyterInputSecret :pythonx InputPrompt(force='<bang>', hide_input=True)

"}}}-------------------------------------------------------------------------- 
"        Key Mappings: {{{
"-----------------------------------------------------------------------------
" Setup plugin mappings for the most common ways to interact with ipython.
noremap  <Plug>Jupyter-RunFile            :update<CR>:pythonx jupyter_vim.run_this_file()<CR>
noremap  <Plug>Jupyter-ImportFile         :update<CR>:pythonx jupyter_vim.run_this_file('-n')<CR>
noremap  <Plug>Jupyter-RunLine            :pythonx jupyter_vim.run_this_line()<CR>
noremap  <Plug>Jupyter-RunCell            :pythonx jupyter_vim.run_this_cell()<CR>
noremap  <Plug>Jupyter-RunLines           :pythonx jupyter_vim.run_these_lines()<CR>
xnoremap <Plug>Jupyter-RunLinesAsTopLevel :pythonx jupyter_vim.dedent_run_these_lines()<CR>
noremap  <Plug>Jupyter-UpdateShell        :pythonx if jupyter_vim.update_subchannel_msgs(force=True): jupyter_vim.vim_echo("vim-ipython shell updated",'Operator')<CR>
"noremap  <Plug>Jupyter-StartDebugging     :pythonx send('%pdb')<CR>
"noremap  <Plug>Jupyter-BreakpointSet      :pythonx set_breakpoint()<CR>
"noremap  <Plug>Jupyter-BreakpointClear    :pythonx clear_breakpoint()<CR>
"noremap  <Plug>Jupyter-DebugThisFile      :pythonx run_this_file_pdb()<CR>
"noremap  <Plug>Jupyter-BreakpointClearAll :pythonx clear_all_breaks()<CR>
noremap  <Plug>Jupyter-PlotClearCurrent   :pythonx jupyter_vim.run_command("plt.clf()")<CR>
noremap  <Plug>Jupyter-PlotCloseAll       :pythonx jupyter_vim.run_command("plt.close('all')")<CR>
noremap  <Plug>Jupyter-RunLineAsTopLevel  :pythonx jupyter_vim.dedent_run_this_line()<CR>
noremap  <Plug>Jupyter-RunTextObj         :<C-u>set opfunc=<SID>opfunc<CR>g@

if g:jupyter_mapkeys
    map  <buffer> <silent> <F5>           <Plug>Jupyter-RunFile
    map  <buffer> <silent> g<F5>          <Plug>Jupyter-ImportFile
    map  <buffer> <silent> <S-F5>         <Plug>Jupyter-RunLine
    map  <buffer> <silent> <F6>           <Plug>Jupyter-RunTextObj
    map  <buffer> <silent> <F9>           <Plug>Jupyter-RunLines
    "map  <buffer> <silent> ,d             <Plug>Jupyter-OpenPyDoc
    map  <buffer> <silent> <M-r>          <Plug>Jupyter-UpdateShell
    map  <buffer> <silent> <S-F9>         <Plug>Jupyter-ToggleReselect
    "map  <buffer> <silent> <C-F6>         <Plug>Jupyter-StartDebugging
    "map  <buffer> <silent> <F6>           <Plug>Jupyter-BreakpointSet
    "map  <buffer> <silent> <S-F6>         <Plug>Jupyter-BreakpointClear
    "map  <buffer> <silent> <F7>           <Plug>Jupyter-DebugThisFile
    "map  <buffer> <silent> <S-F7>         <Plug>Jupyter-BreakpointClearAll
    imap <buffer>          <C-F5>         <C-o><Plug>Jupyter-RunFile
    imap <buffer>          <S-F5>         <C-o><Plug>Jupyter-RunLines
    " imap <buffer> <silent> <F5>           <C-o><Plug>Jupyter-RunFile

    "pi custom
    map  <buffer> <silent> <C-Return>        <Plug>Jupyter-RunFile
    map  <buffer> <silent> <M-S>             <Plug>Jupyter-RunLineAsTopLevel
    xmap <buffer> <silent> <M-S>             <Plug>Jupyter-RunLines
    map  <buffer> <silent> <Leader><Leader>x <Plug>Jupyter-RunCell

    " nnoremap <buffer> <C-c> :<C-u>JupyterInterrupt<CR>
    " inoremap <buffer> <Leader>K <Esc>:<C-u>call <SID>GetDocBuffer()<CR>
endif

"}}}---------------------------------------------------------------------------- 
"       Connect to Jupyter Kernel  {{{
"-------------------------------------------------------------------------------
if g:jupyter_auto_connect
    " General idea: open a channel to the python kernel with vim, use a callback
    " function to determine what to do with the information
    " let s:script_path = fnameescape(expand('<sfile>:p:h:h:h'))
    " let g:logjob = job_start("python " . s:script_path . "/monitor.py", 
    "             \ {'out_io': 'buffer', 'out_name': 'dummy'})
endif
"}}}

"}}}-------------------------------------------------------------------------- 
" TODO move to autoload
"        Functions: {{{
"-----------------------------------------------------------------------------
function! s:opfunc(type)
  " Originally from tpope/vim-scriptease
  let sel_save = &selection
  let cb_save = &clipboard
  let reg_save = @@
  let left_save = getpos("'<")
  let right_save = getpos("'>")
  let vimode_save = visualmode()
  try
    set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus
    if a:type =~ '^\d\+$'
      silent exe 'normal! ^v'.a:type.'$hy'
    elseif a:type =~# '^.$'
      silent exe "normal! `<" . a:type . "`>y"
    elseif a:type ==# 'line'
      silent exe "normal! '[V']y"
    elseif a:type ==# 'block'
      silent exe "normal! `[\<C-V>`]y"
    elseif a:type ==# 'visual'
      silent exe "normal! gvy"
    else
      silent exe "normal! `[v`]y"
    endif
    redraw
    let l:cmd = @@
  finally
    let @@ = reg_save
    let &selection = sel_save
    let &clipboard = cb_save
    exe "normal! " . vimode_save . "\<Esc>"
    call setpos("'<", left_save)
    call setpos("'>", right_save)
  endtry
pythonx << EOF
import textwrap
import vim
jupyter_vim.run_command(textwrap.dedent(vim.eval('l:cmd')))
EOF
endfunction
"}}}

let b:loaded_jupyter = 1
"=============================================================================
"=============================================================================