;;; incar-mode.el --- sample major mode for editing VASP INCAR files.

;; Copyright © 2022, by Lukas Razinkovas

;; Author: Lukas Razinkovas (lukas.razinkovas@gmail.com)
;; Version: 0.1.0
;; Created: 1 Jan 2022
;; Keywords: languages
;; Homepage:

;; This file is not part of GNU Emacs.

;;; License: GNU General Public License version 3

;;; Commentary:

;; Just simple highlighting, completion and wiki documentation of variables

;; TODO: full doc on how to use here


;;; Code:
(require 'json)
(require 'cl-lib)
(require 'company)


(defvar incar-variable-data
      (let* ((json-object-type 'hash-table)
             (json-array-type 'list)
             (json-key-type 'string)
             (json (json-read-file
                    (expand-file-name "variables.json" (file-name-directory load-file-name)))))
        json)
      "INCAR variables and their description.")

(defvar incar-variable-names
  (hash-table-keys incar-variable-data)
  "Names of INCAR tags.")

;; Coloring of variables
(defvar incar-tags-regexp (regexp-opt incar-variable-names 'words))
(defvar incar-font-lock-keywords
      `(
        ("#.*" . font-lock-comment-face)
        ("!.*" . font-lock-comment-face)        
        ("True\\|False\\|\.True\.\\|\.False\." . font-lock-builtin-face)
        (, incar-tags-regexp . font-lock-keyword-face)
        ))


;;; Completion
(defun company-incar-backend (command &optional arg &rest ignored)
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-incar-backend))
    (prefix (and (eq major-mode 'incar-mode)
                 (company-grab-symbol)))
    (candidates
     (cl-remove-if-not
      (lambda (c) (string-prefix-p arg c))
      incar-variable-names))))

(company-incar-backend "IBRION")
(add-to-list 'company-backends 'company-incar-backend)

(defun incar-tag-lookup ()
  "Lookup INCAR tag at point in online documentation."
  (interactive)
  ;; define function variables
  ;; let form defines variables, the * means you can use one definition within another
  (let* ((tag (thing-at-point 'symbol))               ; get tag at point
         (tag-data (gethash tag incar-variable-data)) ; 
         (url (if tag-data (gethash "url" tag-data)))   ; 
         (buff (get-buffer-window "*eww*")))          ; check if there exists an eww buffer, get its window
    (if (not url) (message (concat "undefined VASP tag: " tag))
      (if buff
          (with-selected-window buff (eww url))  ; if eww buffer exists, call eww command in that window
        (progn (switch-to-buffer-other-window "*eww*") (eww url))
        )
      )
    ))


(defvar incar-mode-map
  (let ((map (copy-keymap special-mode-map)))
    (define-key map (kbd "\C-c \C-d") 'incar-tag-lookup)
    map)
  "Keymap for incar-mode.")

;;; Autoload
(define-derived-mode incar-mode text-mode
  "INCAR mode"
  "Major mode for editing VASP INCAR files"
  ;; code for syntax highlighting
  (local-set-key "\C-c \C-d" 'incar-tag-lookup)
  (setq-local comment-start "# ")
  (setq-local comment-end "")
  (setq-local font-lock-defaults '((incar-font-lock-keywords))))


(add-to-list 'auto-mode-alist '("INCAR" . incar-mode))


;; add the mode to the `features' list
(provide 'incar-mode)

;; Local Variables:
;; coding: utf-8
;; End:

;;; incar-mode.el ends here
