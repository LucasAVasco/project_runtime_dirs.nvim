; extends


; Allows to inject other languages in Lua variables as the following:
;
; -- --[[<language>]]
; local var_name = [[
;   injected file content...
; ]]
;
; Does not work if the injected variable is the first one in a function
(_
  (comment
    (comment
      content: (comment_content) @injection.language))
  local_declaration: (variable_declaration
    (assignment_statement
      (expression_list
        value: (string
          content: (string_content) @injection.content )))))