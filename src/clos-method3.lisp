;;;; Common Lisp Object System for CLISP
;;;; Methods
;;;; Part n-2: make/initialize-instance methods, generic functions.
;;;; Bruno Haible 21.8.1993 - 2004
;;;; Sam Steingold 1998 - 2004
;;;; German comments translated into English: Stefan Kain 2002-04-08

(in-package "CLOS")


;;; Lift the initialization protocol.

(defmethod initialize-instance ((method standard-method) &rest args
                                &key qualifiers
                                     ;lambda-list
                                     ;specializers
                                     function
                                     ;documentation
                                     initfunction
                                     wants-next-method-p
                                     parameter-specializers
                                     signature
                                     gf
                                     origin
                                &allow-other-keys)
  (declare (ignore qualifiers function initfunction wants-next-method-p
                   parameter-specializers signature gf origin))
  (apply #'initialize-instance-<standard-method> method args))

(defmethod initialize-instance ((method standard-accessor-method) &rest args
                                &key slot-definition
                                &allow-other-keys)
  (declare (ignore slot-definition))
  (apply #'initialize-instance-<standard-accessor-method> method args))

(defmethod reinitialize-instance ((instance method) &rest initargs)
  (declare (ignore initargs))
  (error (TEXT "~S: The MOP does not allow reinitializing ~S")
         'reinitialize-instance instance))


;; MOP p. 82
(defgeneric method-qualifiers (method)
  (:method ((method standard-method))
    (std-method-qualifiers method)))

;; MOP p. 82
(defgeneric method-lambda-list (method)
  (:method ((method standard-method))
    (std-method-lambda-list method)))

;; MOP p. 82
(defgeneric method-specializers (method)
  (:method ((method standard-method))
    (std-method-specializers method)))

(defgeneric function-keywords (method)
  (:method ((method standard-method))
    (let ((sig (std-method-signature method)))
      (values (sig-keywords sig) (sig-allow-p sig)))))

;; MOP p. 83
(defgeneric accessor-method-slot-definition (method)
  (:method ((method standard-accessor-method))
    (%accessor-method-slot-definition method)))
