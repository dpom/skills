;; -*- lexical-binding: t; -*-

(require 'cl-lib)

(defun agent-skill-buffer--narrowed-text (buf start end regexp)
  "Return the contents of BUF narrowed by START, END, and REGEXP.

START and END are a 1-based inclusive line range.  REGEXP, when
non-nil, keeps only the lines that match it.  Returns a string."
  (with-current-buffer buf
    (let* ((first (or start 1))
           (last (or end (line-number-at-pos (point-max))))
           (begin (save-excursion
                    (goto-char (point-min))
                    (forward-line (1- first))
                    (point)))
           (finish (save-excursion
                     (goto-char (point-min))
                     (forward-line last)
                     (point)))
           (region (buffer-substring-no-properties begin finish)))
      (if regexp
          (mapconcat #'identity
                     (cl-remove-if-not
                      (lambda (line) (string-match-p regexp line))
                      (split-string region "\n"))
                     "\n")
        region))))

(cl-defun agent-skill-buffer (&key buffer start end regexp)
  "Read the contents of the Emacs buffer named BUFFER.

START and END narrow the read to a 1-based inclusive line range.
REGEXP, when given, keeps only the lines that match it.

Return value is a plist:
  (:buffer NAME
   :exists BOOL
   :lines N          ; total lines in the buffer
   :chars N          ; chars in the returned text
   :buffers (NAMES)  ; list of live buffers when BUFFER is missing
   :text TEXT)"
  (let ((buf (get-buffer buffer)))
    (if (not buf)
        (list :buffer buffer
              :exists nil
              :buffers (mapcar #'buffer-name (buffer-list)))
      (let ((text (agent-skill-buffer--narrowed-text buf start end regexp)))
        (list :buffer buffer
              :exists t
              :lines (with-current-buffer buf
                       (line-number-at-pos (point-max)))
              :chars (length text)
              :text text)))))

(provide 'agent-skill-buffer)
