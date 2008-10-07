;; multithreading for CLISP

(defpackage "THREADS"
  (:nicknames "MT" "MP")
  (:use "COMMON-LISP" "EXT")
  (:export "THREAD" "MAKE-THREAD" "THREAD-WAIT"
           "WITHOUT-INTERRUPTS" "THREAD-YIELD" "THREAD-KILL"
           "THREAD-INTERRUPT" "THREADP" "THREAD-NAME"
           "THREAD-ACTIVE-P" "THREAD-STATE" "CURRENT-THREAD" "LIST-THREADS"
           "MAKE-LOCK" "THREAD-LOCK" "THREAD-UNLOCK" "WITH-LOCK"
           "Y-OR-N-P-TIMEOUT" "YES-OR-NO-P-TIMEOUT" "WITH-TIMEOUT"
	    "SYMBOL-VALUE-THREAD" "*DEFAULT-SPECIAL-BINDINGS*"))

(in-package "MT")

(use-package '("MT") "EXT")
(re-export "MT" "EXT")

;; definitions

;; declare special variable for thread's whostate
(defvar *THREAD-WHOSTATE* nil)

;; TODO: add more variables (something should done about the 
;; standartd input/output streams. 
(defvar *DEFAULT-SPECIAL-BINDINGS*
  '((*random-state* . (make-random-state nil))
    (*print-base* . 10)
    (*gensym-counter* . 0)
    (ext:*command-index* . 0)
    (*thread-whostate* . nil)
    (*readtable* . (copy-readtable nil))))

(defsetf SYMBOL-VALUE-THREAD MT::SET-SYMBOL-VALUE-THREAD)

(defmacro with-timeout ((seconds &body timeout-forms) &body body)
  "Execute BODY; if execution takes more than SECONDS seconds,
terminate and evaluate TIMEOUT-FORMS."
  `(call-with-timeout ,seconds (lambda () ,@timeout-forms) (lambda () ,@body)))

(defun timeout-message (default localinfo)
  (write-string (SYS::TEXT "[Timed out] "))
  (write-string (string (car (funcall (if default #'cdr #'car) localinfo))))
  (terpri)
  default)

(defun y-or-n-p-timeout (seconds default &rest args)
  "Y-OR-N-P with timeout."
  (declare (ignorable seconds default))
  (with-timeout (seconds (timeout-message default (localized 'sys::y-or-n)))
    (apply #'y-or-n-p args)))

(defun yes-or-no-p-timeout (seconds default &rest args)
  "YES-OR-NO-P with timeout."
  (declare (ignorable seconds default))
  (with-timeout (seconds (timeout-message default (localized 'sys::yes-or-no)))
    (apply #'yes-or-no-p args)))

;;; locks

(defstruct (lock (:constructor make-lock (name)))
  name owner)

(defun thread-lock (lock &optional whostate timeout)
  (thread-wait whostate timeout lock)
  (setf (lock-owner lock) (current-thread)))

(defun thread-unlock (lock)
  (let ((self (current-thread)) (owner (lock-owner lock)))
    (when owner
      (unless (eq owner self)
        (error (SYS::TEXT "~S: ~S does not own ~S") 'thread-unlock self lock))
      (setf (lock-owner lock) nil))))

(defmacro with-lock ((lock) &body body)
  "Execute BODY with LOCK locked."
  (let ((lk (gensym "WL-")))
    `(let ((,lk ,lock))
      (unwind-protect (progn (thread-lock ,lk) ,@body)
        (thread-unlock ,lk)))))
