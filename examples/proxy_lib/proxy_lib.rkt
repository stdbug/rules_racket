#lang racket/base

(require lib/lib)

(provide proxy_greet proxy_add)

(define (proxy_greet name)
  (greet name))

(define (proxy_add a b)
  (add a b))
