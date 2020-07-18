#lang racket/base

(require rackunit
         proxy_lib/proxy_lib
         "lib/lib.rkt")

(check-equal? (greet "world") "Hello, world!" "String test")
(check-equal? (greet "world") (proxy_greet "world") "String match test")

(check-equal? (add 1 2) 3 "Add test")
(check-equal? (add 1 2) (proxy_add 1 2) "Add match test")
