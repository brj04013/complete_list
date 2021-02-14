function! complete_list#Init()

  let s:keysCode = [
    \ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    \ 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    \ 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    \ 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    \ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    \ ':', '#', '.', '!', '?', '_', '-',
    \ '<BS>', '<DEL>', '<Space>', '<CR>',]       

  let s:keysCode1 = [
    \ '<Up>', '<Down>', '<PageUp>', '<PageDown>',]
  
  let s:keysCode2 = [
    \ '<TAB>',]     
  
  for key in s:keysCode
    execute printf('inoremap <silent> %s %s<C-R>=complete_list#Input()<CR>', key, key)
  endfor

  for key in s:keysCode1
    execute printf('inoremap <silent> %s %s<C-R>=complete_list#FloatingWindows()<CR>', key, key)
  endfor

  for key in s:keysCode2
    execute printf('inoremap <silent> %s %s<C-R>=complete_list#ReplaceInput()<CR>', key, key)
  endfor

  let s:currentWindow = 0
  let s:currentBuffer = 0
  
  let s:currentLine = 0
  let s:currentColumn = 0
  let s:currentInputLength = 0
  
  let s:floatWinLeft = 0
  let s:floatBufLeft = 0
  let s:floatWinLeftLine = 0
  let s:floatWinRight = 0
  let s:floatBufRight = 0
  
  autocmd InsertLeave * 
    \ if s:floatWinLeft > 0 && s:floatWinRight > 0 | 
    \ call nvim_win_close(s:floatWinLeft, v:true) | 
    \ call nvim_win_close(s:floatWinRight, v:true) | 
    \ let s:currentWindow = 0 |
    \ let s:currentBuffer = 0 |
    \ let s:currentLine = 0 | 
    \ let s:currentColumn = 0 | 
    \ let s:currentInputLength = 0 | 
    \ let s:floatWinLeft = 0 | 
    \ let s:floatBufLeft = 0 | 
    \ let s:floatWinLeftLine = 0 | 
    \ let s:floatWinRight = 0 |
    \ let s:floatBufRight = 0 |  
    \ endif

  return ''
endfunction

function! complete_list#Input()
  let extension = expand('%:e')
  if extension != 'rb'
    return ''
  endif
  let s:str = matchstr(strpart(getline('.'), 0, col('.') - 1), '\k*$')
  let s:list = complete_list#List(s:str)
  if len(s:str) == 0 || empty(s:list)
    if s:floatWinLeft > 0 && s:floatWinRight > 0
      call nvim_win_close(s:floatWinLeft, v:true)
      call nvim_win_close(s:floatWinRight, v:true)
     
      let s:currentWindow = 0
      let s:currentBuffer = 0
  
      let s:currentLine = 0
      let s:currentColumn = 0
      let s:currentInputLength = 0
  
      let s:floatWinLeft = 0
      let s:floatBufLeft = 0
      let s:floatWinLeftLine = 0 
      let s:floatWinRight = 0
      let s:floatBufRight = 0
     endif
  else
    let s:currentInputLength = len(s:str)
    
    if s:floatWinLeft > 0 && s:floatWinRight > 0
    
      call nvim_buf_set_lines(s:buf_menu, 0, len(getbufline(s:buf_menu, 1, '$')), 0, s:list)
      let opcion = nvim_buf_get_lines(s:buf_menu, 0, 1, v:false)
      call nvim_buf_set_lines(s:buf_menu_doc, 0, len(getbufline(s:buf_menu_doc, 1, '$')), 0, systemlist('ri -f markdown ' . opcion[0]))
      
    else
    
      let s:currentWindow = nvim_get_current_win()
      let s:currentBuffer = nvim_get_current_buf()
      let s:currentLine = line('.')
      let s:currentColumn = col('.') - s:currentInputLength + 1
        
      let opts0 = {
        \ 'relative': 'cursor',
        \ 'row': 1,
        \ 'col': 0,
        \ 'width': 75,
        \ 'height': 40,
        \ 'focusable': v:false
        \ }
      let s:buf_menu = nvim_create_buf(v:false, v:true)
      call nvim_buf_set_lines(s:buf_menu, 0, len(getbufline(s:buf_menu, 1, '$')), 0, s:list)
      let s:floatWinLeft = nvim_open_win(s:buf_menu, v:false, opts0)
      call nvim_win_set_option(s:floatWinLeft, 'winhl', 'Normal:MyHighlight')
      let opcion = nvim_buf_get_lines(s:buf_menu, 0, 1, v:false)
      let opts1 = {
        \ 'relative': 'cursor',
        \ 'row': 1,
        \ 'col': 75,
        \ 'width': 75,
        \ 'height': 40,
        \ 'focusable': v:false
        \ }
      let s:buf_menu_doc = nvim_create_buf(v:false, v:true)
      call nvim_buf_set_lines(s:buf_menu_doc, 0, len(getbufline(s:buf_menu_doc, 1, '$')), 0, systemlist('ri -f markdown ' . opcion[0]))
      let s:floatWinRight = nvim_open_win(s:buf_menu_doc, v:false, opts1)
      call nvim_win_set_option(s:floatWinRight, 'winhl', 'Normal:MyHighlight')
    endif   
  endif
  return ''
endfunction

function! complete_list#FloatingWindows()
  if s:floatWinLeft > 0 && s:floatWinRight > 0
    if s:floatWinLeftLine == 0
      call nvim_set_current_win(s:floatWinLeft)
      let opcion = nvim_buf_get_lines(s:buf_menu, line('.') - 1, line('.'), v:false)
      call nvim_buf_set_lines(s:buf_menu_doc, 0, len(getbufline(s:buf_menu_doc, 1, '$')), 0, systemlist('ri -f markdown ' . opcion[0]))
      let s:floatWinLeftLine = line('.')
    
      let s:floatLeft = 1
      let s:floatRight = 0

	  let chr = ''

      while nr2char(chr) != "\<TAB>" && nr2char(chr) != "\<ESC>"
        try
          let chr = getchar()
          " echo chr

          if chr == "\<DOWN>" || chr == "\<PAGEDOWN>"

            call cursor(line('.') + 1, 1)
            if s:floatLeft == 1 && s:floatRight == 0
              let opcion = nvim_buf_get_lines(s:buf_menu, line('.') - 1, line('.'), v:false)
              call nvim_buf_set_lines(s:buf_menu_doc, 0, len(getbufline(s:buf_menu_doc, 1, '$')), 0, systemlist('ri -f markdown ' . opcion[0]))
              let s:floatWinLeftLine = line('.')
            endif
            redraw

          elseif  chr == "\<UP>" || chr == "\<PAGEUP>"

            call cursor(line('.') - 1, 1)
            if s:floatLeft == 1 && s:floatRight == 0
              let opcion = nvim_buf_get_lines(s:buf_menu, line('.') - 1, line('.'), v:false)
              call nvim_buf_set_lines(s:buf_menu_doc, 0, len(getbufline(s:buf_menu_doc, 1, '$')), 0, systemlist('ri -f markdown ' . opcion[0]))
              let s:floatWinLeftLine = line('.')
            endif
            redraw

          elseif chr == "\<LEFT>"

            if s:floatLeft == 0 && s:floatRight == 1
              let s:floatLeft = 1
              let s:floatRight = 0
              call nvim_set_current_win(s:currentWindow)
              call nvim_set_current_win(s:floatWinLeft)
              redraw
            endif

          elseif chr == "\<RIGHT>"

            if s:floatLeft == 1 && s:floatRight == 0
              let s:floatLeft = 0
              let s:floatRight = 1
              call nvim_set_current_win(s:currentWindow)
              call nvim_set_current_win(s:floatWinRight)
              redraw
            endif

          elseif nr2char(chr) == "\<TAB>"

            let s:floatLeft = 1
            let s:floatRight = 0
            call complete_list#ReplaceInput()

          elseif nr2char(chr) == "\<ESC>"

            let s:floatLeft = 1
            let s:floatRight = 0

            call nvim_win_close(s:floatWinLeft, v:true)
            call nvim_win_close(s:floatWinRight, v:true)
            call cursor(s:currentLine, s:currentColumn + len(s:str) - 1)
            
            let s:currentWindow = 0
            let s:currentBuffer = 0
  
            let s:currentLine = 0
            let s:currentColumn = 0
            let s:currentInputLength = 0
  
            let s:floatWinLeft = 0
            let s:floatBufLeft = 0
            let s:floatWinLeftLine = 0 
            let s:floatWinRight = 0
            let s:floatBufRight = 0

            return ''
          endif
        catch
          echo ''
        finally
          echo ''
        endtry
      endwhile
    endif
  endif
  return ''
endfunction
  
function! complete_list#ReplaceInput()
  if s:floatWinLeft > 0 && s:floatWinRight > 0

    call nvim_win_close(s:floatWinLeft, v:true)
    call nvim_win_close(s:floatWinRight, v:true)

    if s:floatWinLeftLine > 0

      if s:currentColumn - 1 == 1
      
        call nvim_buf_set_lines(
          \ s:currentBuffer,
          \ s:currentLine - 1,
          \ s:currentLine ,
          \ v:false,
          \ [
            \ nvim_buf_get_lines(s:buf_menu, s:floatWinLeftLine - 1, s:floatWinLeftLine, v:false)[0][0:] .
            \ nvim_buf_get_lines(s:currentBuffer, s:currentLine - 1, s:currentLine , v:false)[0][s:currentColumn-2+s:currentInputLength:]
          \ ]
        \ ) 
      
      elseif s:currentColumn - 1 == 2
       
        call nvim_buf_set_lines(
          \ s:currentBuffer,
          \ s:currentLine - 1,
          \ s:currentLine ,
          \ v:false,
          \ [
            \ nvim_buf_get_lines(s:currentBuffer, s:currentLine - 1, s:currentLine , v:false)[0][0:0] .
            \ nvim_buf_get_lines(s:buf_menu, s:floatWinLeftLine - 1, s:floatWinLeftLine, v:false)[0][0:] .
            \ nvim_buf_get_lines(s:currentBuffer, s:currentLine - 1, s:currentLine , v:false)[0][s:currentColumn-2+s:currentInputLength:]
          \ ]
        \ ) 
      
      elseif s:currentColumn - 1 == 3
       
        call nvim_buf_set_lines(
          \ s:currentBuffer,
          \ s:currentLine - 1,
          \ s:currentLine ,
          \ v:false,
          \ [
            \ nvim_buf_get_lines(s:currentBuffer, s:currentLine - 1, s:currentLine , v:false)[0][0:1] .
            \ nvim_buf_get_lines(s:buf_menu, s:floatWinLeftLine - 1, s:floatWinLeftLine, v:false)[0][0:] .
            \ nvim_buf_get_lines(s:currentBuffer, s:currentLine - 1, s:currentLine , v:false)[0][s:currentColumn-2+s:currentInputLength:]
          \ ]
        \ ) 
      
      else
      
        call nvim_buf_set_lines(
          \ s:currentBuffer,
          \ s:currentLine - 1,
          \ s:currentLine ,
          \ v:false,
          \ [
            \ nvim_buf_get_lines(s:currentBuffer, s:currentLine - 1, s:currentLine , v:false)[0][:s:currentColumn-3] .
            \ nvim_buf_get_lines(s:buf_menu, s:floatWinLeftLine - 1, s:floatWinLeftLine, v:false)[0][0:] .
            \ nvim_buf_get_lines(s:currentBuffer, s:currentLine - 1, s:currentLine , v:false)[0][s:currentColumn-2+s:currentInputLength:]
          \ ]
        \ ) 
      
      endif
      
      call cursor(s:currentLine, s:currentColumn+len(nvim_buf_get_lines(s:buf_menu, s:floatWinLeftLine - 1, s:floatWinLeftLine, v:false)[0][1:])) 
      
      else
 
        if s:currentColumn - 1 == 1

          call nvim_buf_set_lines(
            \ s:currentBuffer,
            \ s:currentLine - 1,
            \ s:currentLine,
            \ v:false,
            \ [
              \ nvim_buf_get_lines(s:buf_menu, 0, 1, v:false)[0][0:] .
              \ nvim_buf_get_lines(s:currentBuffer, s:currentLine - 1, s:currentLine, v:false)[0][s:currentColumn-2+s:currentInputLength:]
            \ ]
          \ )  
      
        elseif s:currentColumn - 1 == 2
       
          call nvim_buf_set_lines(
            \ s:currentBuffer,
            \ s:currentLine - 1,
            \ s:currentLine,
            \ v:false,
            \ [
              \ nvim_buf_get_lines(s:currentBuffer, s:currentLine - 1, s:currentLine, v:false)[0][0:0] .
              \ nvim_buf_get_lines(s:buf_menu, 0, 1, v:false)[0][0:] .
              \ nvim_buf_get_lines(s:currentBuffer, s:currentLine - 1, s:currentLine, v:false)[0][s:currentColumn-2+s:currentInputLength:]
            \ ]
          \ )  
      
        elseif s:currentColumn - 1 == 3
       
          call nvim_buf_set_lines(
            \ s:currentBuffer,
            \ s:currentLine - 1,
            \ s:currentLine,
            \ v:false,
            \ [
              \ nvim_buf_get_lines(s:currentBuffer, s:currentLine - 1, s:currentLine, v:false)[0][0:1] .
              \ nvim_buf_get_lines(s:buf_menu, 0, 1, v:false)[0][0:] .
              \ nvim_buf_get_lines(s:currentBuffer, s:currentLine - 1, s:currentLine, v:false)[0][s:currentColumn-2+s:currentInputLength:]
            \ ]
          \ )  
      
      else
        
        call nvim_buf_set_lines(
          \ s:currentBuffer,
          \ s:currentLine - 1,
          \ s:currentLine,
          \ v:false,
          \ [
            \ nvim_buf_get_lines(s:currentBuffer, s:currentLine - 1, s:currentLine, v:false)[0][0:s:currentColumn-3] .
            \ nvim_buf_get_lines(s:buf_menu, 0, 1, v:false)[0][0:] .
            \ nvim_buf_get_lines(s:currentBuffer, s:currentLine - 1, s:currentLine, v:false)[0][s:currentColumn-2+s:currentInputLength:]
          \ ]
        \ )  
      
      endif

      call cursor( s:currentLine, s:currentColumn+len(nvim_buf_get_lines(s:buf_menu, 0, 1, v:false)[0][0:]))  
      
    endif
 
    let s:currentWindow = 0
    let s:currentBuffer = 0
  
    let s:currentLine = 0
    let s:currentColumn = 0
    let s:currentInputLength = 0
  
    let s:floatWinLeft = 0
    let s:floatBufLeft = 0
    let s:floatWinLeftLine = 0 
    let s:floatWinRight = 0
    let s:floatBufRight = 0
  endif
  return ''
endfunction

function! complete_list#List(param)
  let list = []
  let sorting = -1
  if a:param[0:0] == toupper(a:param[0:0])
    for word in systemlist('ri -f markdown ' . a:param)
      if word[0:0] == '#' || sorting == 0
        let sorting = 0
        call add(list, word)
      endif
    endfor  
    if sorting != 0
      for word in systemlist('ri --list -f markdown ' . a:param)
        let sorting = 1
        call add(list, word)
      endfor
    endif
  else
    for word in systemlist('ri -f markdown ' . a:param)
      if word[0:2] == '# .' || sorting == 2
        let sorting = 2
        call add(list, word)
      endif
    endfor  
    if sorting != 2
      for word in systemlist('ri -f markdown ' . a:param)
        let sorting = 3
        if match(word, '::') >= 0 && match(word, '#') == -1
          let word = split(word, '::')[-1]
        elseif match(word, '#') >= 0
          let word = split(word, '#')[-1]
        else				
          let word = word
        endif
        call add(list, word)
      endfor
    endif
  endif    
  if sorting == 0
    return list
  elseif sorting == 1
    return uniq(sort(list))
  elseif sorting == 2
    return list
  elseif sorting == 3
    return uniq(sort(list[2:]))
  else
    return list
  endif
endfunction
