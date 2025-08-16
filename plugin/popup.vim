" fireplace-eval-popup.vim - Show fireplace evaluation results in a popup.

" Guard against multiple loads
if exists("g:loaded_fireplace_eval_popup")
  finish
endif
let g:loaded_fireplace_eval_popup = 1

" Check for necessary features
if !has('popupwin')
    echom "Fireplace Eval Popup: This plugin requires Vim with popup support."
    finish
endif

" Global variable to track the popup window ID
let g:fireplace_eval_popup_id = 0

" Callback function when popup is closed
function! s:PopupClosed(id, result)
    let g:fireplace_eval_popup_id = 0
endfunction

" Function to close the popup manually
function! s:ClosePopup()
    if g:fireplace_eval_popup_id != 0
        call popup_close(g:fireplace_eval_popup_id)
        let g:fireplace_eval_popup_id = 0
    endif
endfunction

" Function to show the evaluation result in a popup
function! s:ShowEvalPopup()
    " Close any existing popup from this plugin
    call s:ClosePopup()

    " Save current window number
    let l:current_win = winnr()

    " Open the last result in a preview window without switching to it.
    " This may fail if there is no history.
    try
        silent Last
    catch
        return
    endtry

    " Find the preview window
    let l:preview_win = -1
    for w in range(1, winnr('$'))
        if getwinvar(w, '&previewwindow')
            let l:preview_win = w
            break
        endif
    endfor

    if l:preview_win == -1
        " Could not find preview window.
        return
    endif

    " Get the buffer content from the preview window
    let l:preview_buf = winbufnr(l:preview_win)
    let l:content = getbufline(l:preview_buf, 1, '$')

    " Close the preview window
    pclose

    " Switch back to original window if focus changed
    if winnr() != l:current_win
        exe l:current_win . 'wincmd w'
    endif

    " Don't show empty popups
    if empty(l:content) || (len(l:content) == 1 && empty(l:content[0]))
        return
    endif

    " Create the popup with the result
    let l:cursor_line = line('.')
    let l:cursor_col = wincol()
    let g:fireplace_eval_popup_id = popup_create(l:content, {
        \ 'line': l:cursor_line + 1,
        \ 'col': l:cursor_col,
        \ 'highlight': 'Visual',
        \ 'moved': 'any',
        \ 'callback': function('s:PopupClosed')
        \ })
endfunction

" Autocommand to trigger the popup after evaluation
augroup fireplace_eval_popup
    autocmd!
    autocmd User FireplaceEvalPost call s:ShowEvalPopup()
augroup END

" Optional: Close popup on Escape
nnoremap <silent> <Esc> :call <SID>ClosePopup()<CR><Esc>
