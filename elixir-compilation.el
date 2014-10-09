;;; elixir-compilation.el --- ..

;; Filename: elixir-compilation.el
;; Description:
;; Author: Samuel Tonini
;; Maintainer: Samuel Tonini
;; Created: So Oct 5 2014
;; Version: 1.0.0
;; URL: http://github.com/tonini/elixir-compilation.el
;; Keywords: elixir, elixirc, elixir compilation

;; The MIT License (MIT)
;;
;; Copyright (c) Samuel Tonini
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy of
;; this software and associated documentation files (the "Software"), to deal in
;; the Software without restriction, including without limitation the rights to
;; use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
;; the Software, and to permit persons to whom the Software is furnished to do so,
;; subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
;; FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
;; COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
;; IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:
;;
;;; Code:




(require 'compile)
(require 'ansi-color)

(defcustom elixir-compilation-compile-command "elixirc"
  "The shell command for elixirc."
  :type 'string
  :group 'elixir-compilation)

(defcustom elixir-compilation-execute-command "elixir"
  "The shell command for elixir."
  :type 'string
  :group 'elixir-compilation)

(defvar elixir-compilation-buffer-name "*elixir compilation*"
  "Name of the elixir compilation output buffer.")

(defvar elixir-compilation--compilation-buffer-name nil
  "Used to store compilation name so recompilation works as expected.")
(make-variable-buffer-local 'elixir-compilation--compilation-buffer-name)

(defvar elixir-compilation--compilation-error-link-options
  '(elixir "\\([a-z./_]+\\):\\([0-9]+\\)\\(: warning\\)?" 1 2 nil (3) 1)
  "File link matcher for `compilation-error-regexp-alist-alist' (matches path/to/file:line).")

(defun elixir-compilation--compilation-kill-any-orphan-proc ()
  "Ensure any dangling buffer process is killed."
  (let ((orphan-proc (get-buffer-process (buffer-name))))
    (when orphan-proc
      (kill-process orphan-proc))))

(define-compilation-mode elixir-compilation-compilation-mode "ElixirCompilation"
  "Elixir compilation mode."
  (progn
    (font-lock-add-keywords nil
                            '(("^Finished in .*$" . font-lock-string-face)
                              ("^ElixirCompilation.*$" . font-lock-string-face)))
    ;; Set any bound buffer name buffer-locally
    (setq elixir-compilation--compilation-buffer-name elixir-compilation--compilation-buffer-name)
    (set (make-local-variable 'kill-buffer-hook)
         'elixir-compilation--compilation-kill-any-orphan-proc)))

(defvar elixir-compilation--save-buffers-predicate
  (lambda ()
    (not (string= (substring (buffer-name) 0 1) "*"))))

(defun elixir-compilation--handle-compilation-once ()
  (remove-hook 'compilation-filter-hook 'elixir-compilation--handle-compilation-once t)
  (delete-matching-lines "\\(elixir-compilation-compilation-mode\\|ElixirCompilation started\\|\n)" (point-min) (point)))

(defun elixir-compilation--handle-compilation ()
  (ansi-color-apply-on-region compilation-filter-start (point)))

(defun elixir-compilation-run (command &optional cmdlist)
  "In a buffer identified by NAME, run CMDLIST in `elixir-compilation-compilation-mode'.
Returns the compilation buffer."
  (save-some-buffers (not compilation-ask-about-save) elixir-compilation--save-buffers-predicate)

  (let* ((elixir-compilation--compilation-buffer-name name)
         (compilation-filter-start (point-min)))
    (with-current-buffer
        (compilation-start
         (mapconcat 'shell-quote-argument
                    (append (list command) cmdlist)
                    " ")
         'elixir-compilation-compilation-mode
         (lambda (b) elixir-compilation--compilation-buffer-name))
      (setq-local compilation-error-regexp-alist-alist
                  (cons elixir-compilation--compilation-error-link-options compilation-error-regexp-alist-alist))
      (setq-local compilation-error-regexp-alist (cons 'elixir compilation-error-regexp-alist))
      (add-hook 'compilation-filter-hook 'elixir-compilation--handle-compilation nil t)
      (add-hook 'compilation-filter-hook 'elixir-compilation--handle-compilation-once nil t))))

(defun elixir-compilation--read-arguments (args)
  (if (equal args nil)
      ""
    (car (split-string (read-string "Additional arguments: ")))))

(defun elixir-compilation-compile-current-buffer (&optional args)
  "Execute current buffer"
  (interactive "P")
  (elixir-compilation-run elixir-compilation-compile-command
                          (list (buffer-file-name) (elixir-compilation--read-arguments args))))

(defun elixir-compilation-execute-current-buffer (&optional args)
  "Execute current buffer"
  (interactive "P")
  (elixir-compilation-run elixir-compilation-execute-command
                          (list (buffer-file-name) (elixir-compilation--read-arguments args))))

;;;###autoload
(define-minor-mode global-elixir-compilation-mode
  "Toggle global-elixir-compilation-mode."
  :global t)

(provide 'elixir-compilation)

;;; elixir-compilation.el ends here
