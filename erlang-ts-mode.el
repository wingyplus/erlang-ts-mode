;;; erlang-ts-mode.el --- Major mode for editing Erlang files using tree-sitter -*- lexical-binding: t; -*-

(require 'treesit)

(declare-function treesit-parser-create "treesit.c")

(defvar erlang-ts-mode--syntax-table
  ;; from erlang.el
  (let ((table (make-syntax-table)))
      (modify-syntax-entry ?\n ">" table)
      (modify-syntax-entry ?\" "\"" table)
      (modify-syntax-entry ?# "." table)
      ;; (modify-syntax-entry ?$ "\\" table)   ;; Creates problems with indentation afterwards
      ;; (modify-syntax-entry ?$ "'" table)    ;; Creates syntax highlighting and indentation problems
      (modify-syntax-entry ?$ "/" table)    ;; Misses the corner case "string that ends with $"
      ;; we have to live with that for now..it is the best alternative
      ;; that can be worked around with "string that ends with \$"
      (modify-syntax-entry ?% "<" table)
      (modify-syntax-entry ?& "." table)
      (modify-syntax-entry ?\' "\"" table)
      (modify-syntax-entry ?* "." table)
      (modify-syntax-entry ?+ "." table)
      (modify-syntax-entry ?- "." table)
      (modify-syntax-entry ?/ "." table)
      (modify-syntax-entry ?: "." table)
      (modify-syntax-entry ?< "." table)
      (modify-syntax-entry ?= "." table)
      (modify-syntax-entry ?> "." table)
      (modify-syntax-entry ?\\ "\\" table)
      (modify-syntax-entry ?_ "_" table)
      (modify-syntax-entry ?| "." table)
      (modify-syntax-entry ?^ "'" table)
      ;; Pseudo bit-syntax: Latin1 double angle quotes as parens.
      ;;(modify-syntax-entry ?\253 "(?\273" table)
      ;;(modify-syntax-entry ?\273 ")?\253" table)
      table)
  "Syntax table for `erlang-ts-mode'.")

(defconst erlang-ts--reserved-keywords
  '("after" "begin" "catch" "case" "end" "fun" "if"
    "of" "receive" "try" "maybe" "else" "when"))

(defconst erlang-ts--reserved-keywords-vector
  (apply #'vector erlang-ts--reserved-keywords))

(defconst erlang-ts--operators
  '("and" "andalso" "band" "bnot" "bor" "bsl" "bsr" "bxor"
    "div" "not" "or" "orelse" "rem" "xor"))

(defconst erlang-ts--operators-vector
  (apply #'vector erlang-ts--operators))

(defconst erlang-ts--predefined-types
  '("any" "arity" "boolean" "byte" "char" "cons" "deep_string"
    "iodata" "iolist" "maybe_improper_list" "module" "mfa"
    "nil" "neg_integer" "none" "non_neg_integer" "nonempty_list"
    "nonempty_improper_list" "nonempty_maybe_improper_list"
    "nonempty_string" "no_return" "pos_integer" "string"
    "term" "timeout" "map" "atom" "binary"))

(defconst erlang-ts--predefined-types-re
  (concat "^" (regexp-opt erlang-ts--predefined-types) "$"))

(defvar erlang-ts-mode--treesit-settings
  (treesit-font-lock-rules
   :language 'erlang
   :feature 'atom
   '((atom) @font-lock-constant-face)

   :language 'erlang
   :feature 'predefined-type
   :override t
   `((call
      expr: (atom) @font-lock-builtin-face
      (:match ,erlang-ts--predefined-types-re @font-lock-builtin-face)))

   :language 'erlang
   :override t
   :feature 'variable
   '((var) @font-lock-variable-name-face
     ((var) @var (:match "^_" @var)) @font-lock-variable-name-face)

   :language 'erlang
   :feature 'number
   '((integer) @font-lock-number-face
     (float) @font-lock-number-face
     (char) @font-lock-constant-face)

   :language 'erlang
   :feature 'string
   '((string) @font-lock-string-face
     (binary) @font-lock-string-face)

   :language 'erlang
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'erlang
   :feature 'bracket
   '((["(" ")" "{" "}" "[" "]" "#"] @font-lock-bracket-face))

   :language 'erlang
   :feature 'operator
   `((["==" "=:=" "=/=" "=<" ">=" "<" ">"]) @font-lock-operator-face
     ([":" ":=" "!" "+" "=" "->" "=>" "|"]) @font-lock-operator-face
     (,erlang-ts--operators-vector) @font-lock-builtin-face)

   :language 'erlang
   :override t
   :feature 'keyword
   `((,erlang-ts--reserved-keywords-vector) @font-lock-keyword-face)

   :language 'erlang
   :feature 'delimeter
   '((["," "." ";"]) @font-lock-delimeter-face)

   :language 'erlang
   :override t
   :feature 'arrow
   '((clause_body "->" @font-lock-function-name-face))

   :language 'erlang
   :override t
   :feature 'lc
   '((lc_exprs "||" @font-lock-keyword-face)
     (generator lhs: (_) "<-" @font-lock-keyword-face)
     (list_comprehension "[" @font-lock-keyword-face
                         _ "]" @font-lock-keyword-face))

   :language 'erlang
   :override t
   :feature 'attribute
   '((module_attribute "-" @font-lock-preprocessor-face
                       "module" @font-lock-preprocessor-face
                       name: (atom) @font-lock-constant-face)
     (export_attribute "-" @font-lock-preprocessor-face
                       "export" @font-lock-preprocessor-face)
     (export_type_attribute "-" @font-lock-preprocessor-face
                            "export_type" @font-lock-preprocessor-face)
     (import_attribute "-" @font-lock-preprocessor-face
                       "import" @font-lock-preprocessor-face))

   :language 'erlang
   :override t
   :feature 'macro
   '((pp_define "-" @font-lock-preprocessor-face
                "define" @font-lock-preprocessor-face))

   :language 'erlang
   :override t
   :feature 'record
   '((record_decl "-" @font-lock-preprocessor-face
                  "record"@font-lock-preprocessor-face)
     (record_name "#" name: (atom) @font-lock-type-face))

   :language 'erlang
   :override t
   :feature 'alias
   '((type_alias) @font-lock-type-face)

   :language 'erlang
   :override t
   :feature 'function
   '((function_clause
      name: (atom) @font-lock-function-name-face)
     (fa) @font-lock-function-name-face)

   :language 'erlang
   :override t
   :feature 'function-call
   '((call expr: (atom) @font-lock-type-face)
     (call expr:
           (remote module:
                   (remote_module module: (atom) @font-lock-type-face ":")
                   fun: (atom) @font-lock-type-face)))

   :language 'erlang
   :override t
   :feature 'guard
   '((guard_clause exprs: (call expr: (atom) @font-lock-builtin-face)))

   :language 'erlang
   :override t
   :feature 'error
   '((ERROR) @font-lock-warning-face))
  "Tree-sitter font-lock settings for `erlang-ts-mode'.")

(add-to-list 'auto-mode-alist '("\\.erl\\'" . erlang-ts-mode))
(add-to-list 'auto-mode-alist '("\\.hrl\\'" . erlang-ts-mode))

;;;###autoload
(define-derived-mode erlang-ts-mode prog-mode "Erlang"
  "Major mode for editing Erlang, powered by tree-sitter."
  :group 'erlang-ts
  :syntax-table erlang-ts-mode--syntax-table

  ;; Comments.
  (setq-local comment-start "% ")
  (setq-local comment-end "")

  ;; Indent.
  (setq-local indent-tabs-mode nil)

  (when (treesit-ready-p 'erlang)
    (treesit-parser-create 'erlang)

    ;; Font-lock.
    (setq-local treesit-font-lock-settings erlang-ts-mode--treesit-settings)

    ;; Attempt to imitate erlang.el font-lock keywords levels
    (setq-local treesit-font-lock-feature-list
                '((atom comment keyword function number)
                  (attribute guard string)
                  (operator macro record variable predefined-type)
                  (function-call arrow lc alias delimeter bracket error)
                  ))

    (treesit-major-mode-setup)))

(provide 'erlang-ts-mode)
