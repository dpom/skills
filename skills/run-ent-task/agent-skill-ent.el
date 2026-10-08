;; -*- lexical-binding: t; -*-

;;; agent-skill-ent.el --- Run ent tasks and read the log -*- lexical-binding: t; -*-

;;; Commentary:

;; Helper for the `ent' agent skill.  Runs an ent build task in a
;; project directory through the running Emacs server, waits for it
;; to finish, and returns the contents of the `*ent-log*' buffer so
;; the agent can process the output.

;;; Code:

(require 'cl-lib)
(require 'ent)

(defun agent-skill-ent--find-project-file (dir)
  "Return the ent project file governing DIR, erroring if none."
  (let* ((default-directory (file-name-as-directory (expand-file-name dir)))
         (initfile (ent--find-project-file)))
    (unless (file-exists-p initfile)
      (error "No %s project file found in or above %s"
             ent-project-config-filename dir))
    initfile))

(defun agent-skill-ent--kill-procs ()
  "Kill the ent dummy process and any lingering ent-shell processes."
  (dolist (proc (process-list))
    (when (string-match-p "ent-shell-" (process-name proc))
      (kill-process proc)))
  (when (and ent--log-proc (process-live-p ent--log-proc))
    (kill-process ent--log-proc)))

(defun agent-skill-ent--wait (timeout)
  "Wait until the ent run in progress finishes.

ent kills the dummy `ent--log-proc' process when the last task is
done, so waiting for it to die is a reliable completion signal.
Gives up after TIMEOUT seconds and errors, after killing leftover
processes."
  (let ((deadline (+ (float-time) timeout)))
    (while (and ent--log-proc
                (process-live-p ent--log-proc)
                (< (float-time) deadline))
      (accept-process-output ent--log-proc 0.1))
    (when (and ent--log-proc (process-live-p ent--log-proc))
      (agent-skill-ent--kill-procs)
      (error "Timed out waiting for ent task after %d seconds" timeout))))

(defun agent-skill-ent--load-project (dir)
  "Initialize ent for the project containing DIR and load its build file.

Binds `default-directory' to DIR so ent finds the project root,
starts a fresh `*ent-log*' buffer, and loads the project init file
\(usually .ent.el) to register its tasks.  Returns the absolute
path of the project file."
  (let ((initfile (agent-skill-ent--find-project-file dir)))
    (ent--init-run)
    (shell-cd (file-name-directory initfile))
    (load initfile)
    initfile))

(defun agent-skill-ent--result (task error-message)
  "Build the run result plist for TASK with ERROR-MESSAGE."
  (let* ((buf (get-buffer ent--log-buffer))
         (text (if buf
                   (with-current-buffer buf
                     (buffer-substring-no-properties (point-min) (point-max)))
                 ""))
         (exit-codes (cl-loop for line in (split-string text "\n")
                              when (string-match "exit with \\([0-9]+\\)" line)
                              collect (string-to-number (match-string 1 line)))))
    (list :task task
          :success (and (null error-message)
                        (cl-every #'zerop exit-codes))
          :timed-out (and error-message
                          (string-match-p "Timed out" error-message)
                          t)
          :error error-message
          :lines (if buf
                     (with-current-buffer buf
                       (line-number-at-pos (point-max)))
                   0)
          :chars (length text)
          :text text)))

(cl-defun agent-skill-ent-run (&key task (dir default-directory) (timeout 600))
  "Run the ent task TASK in the project containing DIR.

TASK runs with all of its dependencies to completion, waiting up to
TIMEOUT seconds.  Returns a plist describing the outcome plus the
full contents of the `*ent-log*' buffer:

  (:task NAME :success BOOL :timed-out BOOL :error STRING-or-nil
   :lines N :chars N :text TEXT)

:success is non-nil only when every shell command exited with status
0 and no task signaled an error."
  (let (error-message
        (fresh-log nil))
    (condition-case err
        (progn
          (agent-skill-ent--load-project dir)
          (setq fresh-log t)
          (ent--ensure-task-exists task)
          (ent--start-next-task (reverse (ent--get-all-deps '() task)))
          (agent-skill-ent--wait timeout))
      (error (setq error-message (error-message-string err))))
    (if fresh-log
        (agent-skill-ent--result task error-message)
      (list :task task
            :success nil
            :timed-out nil
            :error error-message
            :lines 0
            :chars 0
            :text ""))))

(cl-defun agent-skill-ent-tasks (&key (dir default-directory))
  "List the ent tasks defined by the project containing DIR.

Returns (:project-dir P :tasks ((NAME . DOC) ...)).  This does not
touch the `*ent-log*' buffer."
  (condition-case err
      (let ((initfile (agent-skill-ent--find-project-file dir)))
        (setq ent-tasks (make-hash-table :test 'equal))
        (load initfile)
        (list :project-dir (file-name-directory initfile)
              :tasks (cl-loop for name in (ent-task-names)
                              collect (cons name
                                            (ent-task-doc (gethash name ent-tasks))))))
    (error (list :error (error-message-string err)))))

(cl-defun agent-skill-ent-log ()
  "Return the current contents of the `*ent-log*' buffer.

Returns (:exists BOOL :lines N :chars N :text TEXT)."
  (let ((buf (get-buffer ent--log-buffer)))
    (if buf
        (with-current-buffer buf
          (list :exists t
                :lines (line-number-at-pos (point-max))
                :chars (buffer-size)
                :text (buffer-substring-no-properties (point-min) (point-max))))
      (list :exists nil :lines 0 :chars 0 :text ""))))

(provide 'agent-skill-ent)
;;; agent-skill-ent.el ends here
