#lang racket/base

(provide greet add)

(define (greet name)
  (string-append "Hello, " name "!"))

(define (add a b)
  (+ a b))
