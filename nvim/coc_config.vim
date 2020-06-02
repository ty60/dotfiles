" Disable coc-python
autocmd BufNewFile,BufRead *.py call CocAction('toggleExtension', 'coc-python')

call coc#config('languageserver', {
            \ "mpls": {
            \   "command": "dotnet",
            \   "args": [
            \     "exec",
            \     "/usr/local/src/python-language-server/output/bin/Debug/Microsoft.Python.LanguageServer.dll"
            \   ],
            \   "filetypes": ["python"],
            \   "initializationOptions": {
            \     "interpreter": {
            \       "properties": {
            \         "InterpreterPath": "/usr/bin/python3",
            \         "DatabasePath": "/usr/local/src/python-language-server/output",
            \         "Version": "3"
            \       }
            \     },
            \     "searchPaths": [
            \         "/usr/lib/python3/dist-packages"
            \     ],
            \     "testEnvironment": "false",
            \     "analysisUpdates": "true",
            \     "traceLogging": "true",
            \     "asyncStartup": "true",
            \   }
            \ }
            \})