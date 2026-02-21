;; -*- lexical-binding: t; -*-

(require 'cl-macs)
(require 'org)
(require 'ox-html)

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
                  (cl-loop for (name link) in '(("Index" "index.html"))
                           concat (concat "<li><a href=\"" (partial-url exported-filename link) "\">" name "</a></li>"))
                  (org-file-contents "_partials/postamble.html")))

(defun export-page (filename)
  (let* ((stylesheet (concat "<link rel=\"stylesheet\" href=\"" (partial-url filename "assets/css/styles.css") "\" type=\"text/css\">"))
         (head (concat (org-file-contents "_partials/prompt.html") stylesheet)))
    (export-file filename head (navigation-html filename))))

(defun org-babel-expand-noweb-references (&optional info parent-buffer)
  "Expand Noweb references in the body of the current source code block.

For example the following reference would be replaced with the
body of the source-code block named `example-block'.

<<example-block>>

Note that any text preceding the <<foo>> construct on a line will
be interposed between the lines of the replacement text.  So for
example if <<foo>> is placed behind a comment, then the entire
replacement text will also be commented.

This function must be called from inside of the buffer containing
the source-code block which holds BODY.

In addition the following syntax can be used to insert the
results of evaluating the source-code block named `example-block'.

<<example-block()>>

Any optional arguments can be passed to example-block by placing
the arguments inside the parenthesis following the convention
defined by `org-babel-lob'.  For example

<<example-block(a=9)>>

would set the value of argument \"a\" equal to \"9\".  Note that
these arguments are not evaluated in the current source-code
block but are passed literally to the \"example-block\"."
  (let* ((parent-buffer (or parent-buffer (current-buffer)))
         (info (or info (org-babel-get-src-block-info 'light)))
         (lang (nth 0 info))
         (body (nth 1 info))
         (comment (string= "noweb" (cdr (assq :comments (nth 2 info)))))
         (noweb-re (format "\\(.*?\\)\\(%s\\)"
                           (with-current-buffer parent-buffer
                             (org-babel-noweb-wrap))))
         (cache nil)
         (c-wrap
          (lambda (s)
            ;; Comment string S, according to LANG mode.  Return new
            ;; string.
            (unless org-babel-tangle-uncomment-comments
              (with-temp-buffer
                (funcall (org-src-get-lang-mode lang))
                (comment-region (point)
                                (progn (insert s) (point)))
                (org-trim (buffer-string))))))
         (expand-body
          (lambda (i)
            ;; Expand body of code represented by block info I.
            (let ((b (if (org-babel-noweb-p (nth 2 i) :eval)
                         (org-babel-expand-noweb-references i)
                       (nth 1 i))))
              (if (not comment) b
                (let ((cs (org-babel-tangle-comment-links i)))
                  (concat (funcall c-wrap (car cs)) "\n"
                          b "\n"
                          (funcall c-wrap (cadr cs))))))))
         (expand-references
          (lambda (ref cache)
            (pcase (gethash ref cache)
              (`(,last . ,previous)
               ;; Ignore separator for last block.
               (let ((strings (list (funcall expand-body last))))
                 (dolist (i previous)
                   (let ((parameters (nth 2 i)))
                     ;; Since we're operating in reverse order, first
                     ;; push separator, then body.
                     (push (or (cdr (assq :noweb-sep parameters)) "\n")
                           strings)
                     (push (funcall expand-body i) strings)))
                 (mapconcat #'identity strings "")))
              ;; Raise an error about missing reference, or return the
              ;; empty string.
              ((guard (or org-babel-noweb-error-all-langs
                          (member lang org-babel-noweb-error-langs)))
               (error "Cannot resolve %s (see `org-babel-noweb-error-langs')"
                      (org-babel-noweb-wrap ref)))
              (_ "")))))
    (replace-regexp-in-string
     noweb-re
     (lambda (m)
       (with-current-buffer parent-buffer
         (save-match-data
           (let* ((prefix (match-string 1 m))
                  (id (match-string 3 m))
                  (evaluate (string-match-p "(.*)" id))
                  (expansion
                   (cond
                    (evaluate
                     ;; Evaluation can potentially modify the buffer
                     ;; and invalidate the cache: reset it.
                     (setq cache nil)
                     (let ((raw (org-babel-ref-resolve id)))
                       (if (stringp raw) raw (format "%S" raw))))
                    ;; Return the contents of headlines literally.
                    ((org-babel-ref-goto-headline-id id)
                     (org-babel-ref-headline-body))
                    ;; Look for a source block named SOURCE-NAME.  If
                    ;; found, assume it is unique; do not look after
                    ;; `:noweb-ref' header argument.
                    ((org-with-point-at 1
                       (let ((r (org-babel-named-src-block-regexp-for-name id)))
                         (and (re-search-forward r nil t)
                              (not (org-in-commented-heading-p))
                              (funcall expand-body
                                       (org-babel-get-src-block-info t))))))
                    ;; Retrieve from the Library of Babel.
                    ((nth 2 (assoc-string id org-babel-library-of-babel)))
                    ;; All Noweb references were cached in a previous
                    ;; run.  Extract the information from the cache.
                    ((hash-table-p cache)
                     (funcall expand-references id cache))
                    ;; Though luck.  We go into the long process of
                    ;; checking each source block and expand those
                    ;; with a matching Noweb reference.  Since we're
                    ;; going to visit all source blocks in the
                    ;; document, cache information about them as well.
                    (t
                     (setq cache (make-hash-table :test #'equal))
                     (org-with-wide-buffer
                      (org-babel-map-src-blocks nil
                        (if (org-in-commented-heading-p)
                            (org-forward-heading-same-level nil t)
                          (let* ((info (org-babel-get-src-block-info t))
                                 (ref (cdr (assq :noweb-ref (nth 2 info)))))
                            (push info (gethash ref cache))))))
                     (funcall expand-references id cache)))))
             expansion))))
     body t t 2)))

(defun file-under (heading)
  (interactive (list
                (let* ((index (project-has-file-p (project-current) "index.org"))
                       (headlines (org-get-file-headlines index))
                       (level-1-headlines (seq-filter (lambda (item) (= 1 (car item))) headlines)))
                  (completing-read "Headline: " (mapcar #'cadr level-1-headlines)))))
  (let* ((file (buffer-file-name))
         (project (project-current))
         (root (expand-file-name (project-root project))))
    (pcase (org-collect-keywords '("TITLE"))
      (`(("TITLE" ,title))
       (with-current-buffer (find-file (project-has-file-p project "index.org"))
         (beginning-of-buffer)
         (search-forward (concat "* " heading))
         (newline)
         (insert (format "** [[file:%s][%s]]" (string-replace root "" file) title))
         (newline))))))
