;;; lsp-tailwindcss.el --- A lsp-mode client for tailwindcss  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  A.I.

;; Author: A.I. <merrick@luois.me>
;; Keywords: language tools
;; Version: 0.2
;; Package-Requires: ((lsp-mode "7.1") (emacs "26.1"))
;; Keywords: tailwindcss
;; URL: https://github.com/merrickluo/lsp-tailwindcss

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; provide the connection to lsp-mode and tailwindcss language server

;;; Code:
(require 'lsp-mode)

(defgroup lsp-tailwindcss nil
  "lsp support for tailwind css"
  :group 'lsp-mode)

(defcustom lsp-tailwindcss-add-on-mode nil
  "Specify lsp-tailwindcss as add-on so it can work with other language servers."
  :type 'boolean
  :group 'lsp-tailwindcss)

(defcustom lsp-tailwindcss-major-modes '(rjsx-mode web-mode html-mode css-mode)
  "Specify lsp-tailwindcss should only starts when major-mode in the list or derived from them."
  :type 'list
  :group 'lsp-tailwindcss
  :package-version '(lsp-tailwindcss . "0.2"))

(lsp-dependency 'tailwindcss-language-server
                '(:system "tailwindcss-language-server")
                '(:npm
                  :package "@tailwindcss/language-server"
                  :path "tailwindcss-language-server"))

(defun lsp-tailwindcss--activate-p (&rest _args)
  (and (lsp-workspace-root)
       (or (file-exists-p (f-join (lsp-workspace-root) "tailwind.config.js"))
           (file-exists-p (f-join (lsp-workspace-root) "assets" "tailwind.config.js"))
           (locate-dominating-file (buffer-file-name) "tailwind.config.js"))
       (apply #'provided-mode-derived-p major-mode lsp-tailwindcss-major-modes)))

(defun lsp-tailwindcss--company-dash-hack (w)
  (with-lsp-workspace w
    (let* ((caps (lsp--workspace-server-capabilities w))
           (comp (lsp:server-capabilities-completion-provider? caps))
           (trigger-chars (append (lsp:completion-options-trigger-characters? comp) nil)))
      (lsp:set-completion-options-trigger-characters?
       comp
       (vconcat
        (cl-pushnew "-" trigger-chars :test #'string=))))))

(defun lsp-tailwindcss--initialization-options ()
  (ht ("configuration" (lsp-configuration-section "tailwindcss"))))

(lsp-register-client
 (make-lsp-client
  :new-connection (lsp-stdio-connection
                   (lambda ()
                     `(,(lsp-package-path 'tailwindcss-language-server) "--stdio")))
  :activation-fn #'lsp-tailwindcss--activate-p
  :server-id 'tailwindcss
  :priority -1
  :add-on? lsp-tailwindcss-add-on-mode
  :initialization-options #'lsp-tailwindcss--initialization-options
  :initialized-fn #'lsp-tailwindcss--company-dash-hack
  :download-server-fn (lambda (_client callback error-callback _update?)
                        (when lsp-tailwindcss-auto-install-server
                          (lsp-package-ensure 'tailwindcss-language-server callback error-callback)))))

(provide 'lsp-tailwindcss)
;;; lsp-tailwindcss.el ends here
