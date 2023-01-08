;;; erlang-ts-mode.el --- Major mode for editing Erlang files using tree-sitter -*- lexical-binding: t; -*-

(require 'treesit)

(declare-function treesit-parser-create "treesit.c")

(defvar erlang-ts-mode--treesit-settings
  (treesit-font-lock-rules
   :language 'erlang
   :feature 'atom
   '((atom) @font-lock-constant-face)

   :language 'erlang
   :feature 'variable
   '((var) @font-lock-variable-name-face)

   :language 'erlang
   :feature 'number
   '((integer) @font-lock-number-face
     (float) @font-lock-number-face)

   :language 'erlang
   :override t
   :feature 'string
   '((string) @font-lock-string-face
     (binary) @font-lock-string-face)

   :language 'erlang
   :feature 'comment
   '((comment) @font-lock-comment-face)

   ;; BUG: delimeter cause highlight due to this feature override it.
   :language 'erlang
   :override t
   :feature 'attribute
   '((module_attribute
      name: (atom) @font-lock-constant-face) @font-lock-type-face
     (export_attribute) @font-lock-type-face
     (export_type_attribute) @font-lock-type-face
     (import_attribute) @font-lock-type-face)

   :language 'erlang
   :override t
   :feature 'alias
   '((type_alias) @font-lock-type-face) 

   :language 'erlang
   :override t
   :feature 'function
   '((function_clause
      name: (atom) @font-lock-function-name-face
      "when" @font-lock-keyword-face)
     (function_clause
      name: (atom) @font-lock-function-name-face)
     (fa) @font-lock-function-name-face
     (anonymous_fun "end" @font-lock-keyword-face)
     (call expr: (atom) @font-lock-function-name-face))

   :language 'erlang
   :override t
   :feature 'bracket
   '((["(" ")" "{" "}" "[" "]" "#"] @font-lock-bracket-face))

   :language 'erlang
   :feature 'operator
   '((["==" "=:=" "=/=" "=<" ">=" "<" ">"]) @font-lock-operator-face
     ([":" ":=" "!" "+" "=" "->" "=>" "|"]) @font-lock-operator-face)

   :language 'erlang
   :feature 'keyword
   '((["fun" "div"]) @font-lock-keyword-face)

   :language 'erlang
   :override t
   :feature 'delimeter
   '((["," "." ";"]) @font-lock-delimeter-face)

   :language 'erlang
   :override t
   :feature 'error
   '((ERROR) @font-lock-warning-face))
  "Tree-sitter font-lock settings for `erlang-ts-mode'.")

(add-to-list 'auto-mode-alist '("\\.erl\\'" . erlang-ts-mode))
(add-to-list 'auto-mode-alist '("\\.hrl\\'" . erlang-ts-mode))

;;;###autoload
(define-derived-mode erlang-ts-mode prog-mode "Erlang"
  :group 'erlang
  ;; TODO: look at in erlang.el to see how they use syntax-table.
  :syntax-table nil

  (when (treesit-ready-p 'erlang)
    (treesit-parser-create 'erlang)
    ;; Comments.
    (setq-local comment-start "% ")
    (setq-local comment-end "")

    ;; Indent.
    (setq-local indent-tabs-mode 0)

    ;; Font-lock.
    (setq-local treesit-font-lock-settings erlang-ts-mode--treesit-settings)
    ;; TODO: clarify feature list order.
    (setq-local treesit-font-lock-feature-list
		'((atom variable number string)
		  (comment)
		  (attribute function alias delimeter bracket keyword)
		  (operator delimeter bracket)))

    (treesit-major-mode-setup)))

(provide 'erlang-ts-mode)
