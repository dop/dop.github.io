;; -*- lexical-binding: t; -*-

(require 'cl-macs)
(require 'org)
(require 'ox-html)

(defvar blog-title-suffix (format " - %s weblog" user-full-name))

(defun export-file (filename head postamble)
  (with-current-buffer (find-file-literally filename)
    (let ((org-html-doctype "html5")
          (org-html-htmlize-output-type nil)
          (org-html-head-include-default-style nil)
          (org-html-head-include-scripts nil)
          (org-html-postamble postamble)
          (org-html-head head)
          (org-html-self-link-headlines t))
      (org-html-export-to-html))))

(defun slugify (text)
  (string-trim (replace-regexp-in-string "[^a-zA-Z0-9_-]+" "-" text) "-" "-"))

(defun org-headline-get-text (data)
  (let* ((title (plist-get data :title))
         (texts (org-element-map title '(plain-text) #'substring-no-properties)))
    (mapconcat #'identity texts " ")))

(defun org-get-file-headlines (file)
  (with-current-buffer (find-file-noselect file)
    (org-element-map (org-element-parse-buffer) '(headline)
      (lambda (headline)
        (let ((data (elt headline 1)))
          (list (plist-get data :level) (org-headline-get-text data)))))))

(defun org-html--headline-reference (fn datum &rest args)
  (cl-case (org-element-type datum)
    (headline
     (let* ((title (plist-get (elt datum 1) :title))
            (texts (org-element-map title '(plain-text) #'substring-no-properties)))
       (slugify (mapconcat #'identity texts " "))))
    (t
     (apply fn datum args))))

(advice-add 'org-html--reference :around #'org-html--headline-reference)

(defun partial-url (exported-filename resource)
  (let ((prefix (cl-loop repeat (1- (length (split-string exported-filename "/"))) concat "../")))
    (concat prefix resource)))

(defun navigation-html (exported-filename)
  (string-replace "<!-- links -->"
                  (cl-loop for (name link) in '(("Index" "index.html")
                                                ("Resumé" "pages/resume.html"))
                           concat (concat "<li><a href=\"" (partial-url exported-filename link) "\">" name "</a></li>"))
                  (org-file-contents "_partials/postamble.html")))

(defun export-page (filename)
  (let* ((stylesheet (concat "<link rel=\"stylesheet\" href=\"" (partial-url filename "assets/css/styles.css") "\" type=\"text/css\">"))
         (head (concat (org-file-contents "_partials/prompt.html") stylesheet)))
    (export-file filename head (navigation-html filename))))

(defun add-author-to-title (fn info)
  (let* ((title (substring-no-properties (car (org-element-contents (org-element-copy (plist-get info :title))))))
         (subtitle (when-let* ((org-subtitle (plist-get info :subtitle))
                               (type (org-element-type (car org-subtitle))))
                     (when (or (eq 'string type) (eq 'plain-text type))
                       (substring-no-properties (car org-subtitle)))))
         (new-title (concat title (if subtitle (concat ": " subtitle) "") blog-title-suffix)))
    (funcall fn (append (list :title (org-element-create 'string nil new-title)) info))))

(advice-add 'org-html--build-meta-info :around #'add-author-to-title)
