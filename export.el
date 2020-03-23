(add-to-list 'load-path "~/.emacs.d/elpa/htmlize-20191111.2130")

(require 'org)
(require 'ox-html)

(defvar default-styles
  (concat "<style type=\"text/css\">"
          (org-file-contents "_partials/default-styles.css")
          "</style>"
          "<script>"
          (org-file-contents "_partials/navigation.js")
          "</script>"))

(defun export-file (filename &optional head postamble)
  (with-current-buffer (find-file-literally filename)
    (let ((org-html-doctype "html5")
          (org-html-htmlize-output-type 'css)
          (org-html-head-include-default-style nil)
          (org-html-head-include-scripts nil)
          (org-html-postamble postamble)
          (org-html-head head))
      (org-html-export-to-html))))

(defun export-post (filename head)
  (export-file filename head (org-file-contents "_partials/postamble.html")))

(defun export-final-post (filename)
  (export-post filename default-styles))

(defun export-development-post (filename)
  (export-post filename
               (concat "<link rel=\"stylesheet\" href=\"default-styles.css\" type=\"text/css\">"
                       "<script src=\"navigation.js\"></script>")))
