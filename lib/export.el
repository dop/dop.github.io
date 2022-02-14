;; -*- lexical-binding: t; -*-

(require 'cl-macs)
(require 'org)
(require 'ox-html)

(defvar *export-inlined* t
  "Whether to inline scripts and styles. NIL is useful for development.")

(defvar inline-styles
  (concat "<style type=\"text/css\">" (org-file-contents "_partials/styles.css") "</style>"))

(defun export-file (filename &optional head postamble)
  (with-current-buffer (find-file-literally filename)
    (let ((org-html-doctype "html5")
          (org-html-htmlize-output-type nil)
          (org-html-head-include-default-style nil)
          (org-html-head-include-scripts nil)
          (org-html-postamble postamble)
          (org-html-head head))
      (org-html-export-to-html))))

(defun partial-url (exported-filename resource)
  (let ((prefix (cl-loop repeat (1- (length (split-string exported-filename "/"))) concat "../")))
    (concat prefix resource)))

(defun navigation-html (exported-filename)
  (string-replace "<!-- links -->"
                  (cl-loop for (name link) in '(("Posts" "index.html") ("Pages" "pages.html"))
                           concat (concat "<li><a href=\"" (partial-url exported-filename link) "\">" name "</a></li>"))
                  (org-file-contents "_partials/postamble.html")))

(defun export-page (filename)
  (let ((head (if *export-inlined*
                  (concat "<style type=\"text/css\">" (org-file-contents "_partials/styles.css") "</style>")
                (concat "<link rel=\"stylesheet\" href=\"" (partial-url filename "_partials/styles.css") "\" type=\"text/css\">"))))
    (export-file filename head (navigation-html filename))))

(defun export-development-page (filename)
  (export-post filename
               (concat "<link rel=\"stylesheet\" href=\"styles.css\" type=\"text/css\">")))
