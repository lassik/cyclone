;;;; Cyclone Scheme
;;;; https://github.com/justinethier/cyclone
;;;;
;;;; Copyright (c) 2014-2016, Justin Ethier
;;;; All rights reserved.
;;;;
;;;; This module contains the base library from r7rs.
;;;;
(define-library (scheme base)
  (import (scheme cyclone common))
  (export
    member
    assoc
    cons-source
    syntax-rules
    letrec*
    guard
    guard-aux
    ;; Record types
    define-record-type
    record?
    is-a?
    register-simple-type
    make-type-predicate
    make-constructor
    make-constructor/args
    make-getter
    make-setter
    slot-ref
    slot-set!
    type-slot-offset
    ;; END records
    receive
    abs
    max
    min
    modulo
    floor-remainder
    even?
    exact-integer?
    exact-integer-sqrt
    exact?
    inexact?
    odd?
    complex?
    rational?
    bignum?
    gcd
    lcm
    quotient
    remainder
    truncate-quotient 
    truncate-remainder 
    truncate/ 
    floor-quotient 
    floor-remainder 
    floor/ 
    square
    expt
    call-with-current-continuation
    call/cc
    call-with-values
    dynamic-wind
    values
    char=?
    char<?
    char>?
    char<=?
    char>=?
    string=?
    string<?
    string<=?
    string>?
    string>=?
    foldl
    foldr
    not
    list?
    zero?
    positive?
    negative?
    append
    list
    make-list
    list-copy
    map
    Cyc-map-loop-1
    Cyc-for-each-loop-1
    for-each
    list-tail
    list-ref
    list-set!
    reverse
    boolean=?
    symbol=?
    Cyc-obj=?
    vector
    vector-append
    vector-copy
    vector-copy!
    vector-fill!
    vector->list
    vector->string
    vector-map
    vector-for-each
    make-string
    string
    string-copy
    string-copy!
    string-fill!
    string->list
    string->vector
    string-map
    string-for-each
    ;get-param-objs ;; TODO: only for debugging!!
    make-parameter
    current-output-port
    current-input-port
    current-error-port
    call-with-port
    error-object?
    error-object-message
    error-object-irritants
    ; TODO: file-error?
    ; TODO: read-error?
    error
    raise
    raise-continuable
    with-handler
    with-exception-handler
    Cyc-add-exception-handler
    Cyc-remove-exception-handler
    newline
    write-char
    write-string
    flush-output-port
    peek-char
    read-char
    read-line
    read-string
    input-port?
    output-port?
    input-port-open?
    output-port-open?
    get-output-string
    open-output-string
    open-input-string
    get-output-bytevector
    open-input-bytevector
    open-output-bytevector
    features
    Cyc-add-feature!
    Cyc-version
    any
    every
    and
    or
    let
    let*
    letrec
    let*-values
    let-values
    begin
    case
    cond
    cond-expand
    do
    when
    unless
    quasiquote
    floor
    ceiling
    truncate
    round
    exact
    inexact
    eof-object
    syntax-error
    bytevector-copy
    bytevector-copy!
    utf8->string
    string->utf8
    denominator
    numerator
    parameterize

;;;;
; Possibly missing functions:
;
;    ; following byte vector functions are not implemented yet:
;    read-bytevector
;    read-bytevector!
;    write-bytevector
;
;    : No unicode support at this time
    peek-u8
    read-u8
;    u8-ready?
    write-u8
;
;    ; No complex or rational numbers at this time
;    rationalize
;
;    ;; no binary/text ports yet
;    binary-port?
;    textual-port?
;
;    ;; syntax-rules
;    define-values
;
; unclassified TODO's:
;    import
;    include
;    let-syntax
;    letrec-syntax
;;;;
  )
  (inline
    square
    quotient
    numerator
    denominator
    truncate
    negative?
    positive?
    zero?
    list?
    not
    string>=?
    string>?
    string<=?
    string<?
    string=?
  )
  (begin
    ;; Features implemented by this Scheme
    (define (features) 
      (cons 
        'cyclone
        (cons
          (string->symbol 
            (string-append "version-" *version-number*))
          (cons
            (string->symbol (Cyc-compilation-environment 'platform))
            *other-features*))))

    (define *other-features* 
            '(r7rs 
              ieee-float
              full-unicode
              posix))

    ;; Designed for internal use only, don't call this in user code!!
    (define (Cyc-add-feature! sym)
      (set! *other-features* (cons sym *other-features*)))

    (define (Cyc-version) *version-number*)

    (define-syntax and
      (er-macro-transformer
       (lambda (expr rename compare)
         (cond ((null? (cdr expr)) #t)
               ((null? (cddr expr)) (cadr expr))
               (else (list (rename 'if) (cadr expr)
                           (cons (rename 'and) (cddr expr))
                           #f))))))
    (define-syntax or
      (er-macro-transformer
        (lambda (expr rename compare)
          (cond ((null? (cdr expr)) #f)
                ((null? (cddr expr)) (cadr expr))
                (else
                 (list (rename 'let) (list (list (rename 'tmp) (cadr expr)))
                       (list (rename 'if) (rename 'tmp)
                             (rename 'tmp)
                             (cons (rename 'or) (cddr expr)))))))))
    (define-syntax let
      (er-macro-transformer
        (lambda (expr rename compare)
          (if (null? (cdr expr)) (error "empty let" expr))
          (if (null? (cddr expr)) (error "no let body" expr))
          ((lambda (bindings)
             (if (list? bindings) #f (error "bad let bindings"))
             (if (every (lambda (x)
                          (if (pair? x) (if (pair? (cdr x)) (null? (cddr x)) #f) #f))
                        bindings)
                 ((lambda (vars vals)
                    (if (symbol? (cadr expr))
                        `((,(rename 'lambda) ,vars
                           (,(rename 'letrec) ((,(cadr expr)
                                                (,(rename 'lambda) ,vars
                                                 ,@(cdr (cddr expr)))))
                            (,(cadr expr) ,@vars)))
                          ,@vals)
                        `((,(rename 'lambda) ,vars ,@(cddr expr)) ,@vals)))
                  (map car bindings)
                  (map cadr bindings))
                 (error "bad let syntax" expr)))
           (if (symbol? (cadr expr)) (car (cddr expr)) (cadr expr))))))
    (define-syntax let*
      (er-macro-transformer
        (lambda (expr rename compare)
          (if (null? (cdr expr)) (error "empty let*" expr))
          (if (null? (cddr expr)) (error "no let* body" expr))
          (if (null? (cadr expr))
              `(,(rename 'let) () ,@(cddr expr))
              (if (if (list? (cadr expr))
                      (every
                       (lambda (x)
                         (if (pair? x) (if (pair? (cdr x)) (null? (cddr x)) #f) #f))
                       (cadr expr))
                      #f)
                  `(,(rename 'let) (,(caar (cdr expr)))
                    (,(rename 'let*) ,(cdar (cdr expr)) ,@(cddr expr)))
                  (error "bad let* syntax"))))))
    (define-syntax letrec 
      (er-macro-transformer
        (lambda (exp rename compare)
          (let* ((bindings  (cadr exp)) ;(letrec->bindings exp)
                 (namings   (map (lambda (b) (list (car b) #f)) bindings))
                 (names     (map car (cadr exp))) ;(letrec->bound-vars exp)
                 (sets      (map (lambda (binding) 
                                   (cons 'set! binding))
                                 bindings))
                 (args      (map cadr (cadr exp)))) ;(letrec->args exp)
            `(let ,namings
               (begin ,@(append sets (cddr exp)))))))) ;(letrec->exp exp)
;; NOTE: chibi uses the following macro. turns vars into defines?
;;(define-syntax letrec
;;  (er-macro-transformer
;;   (lambda (expr rename compare)
;;     ((lambda (defs)
;;        `((,(rename 'lambda) () ,@defs ,@(cddr expr))))
;;      (map (lambda (x) (cons (rename 'define) x)) (cadr expr))))))
    (define-syntax begin 
      (er-macro-transformer
        (lambda (exp rename compare)
          (define (singlet? l)
            (and (list? l)
                 (= (length l) 1)))
          
          (define (dummy-bind exps)
            (cond
              ((singlet? exps)  (car exps))
              
              ; JAE - should be fine until CPS phase
              ((pair? exps)
               `((lambda ()
                 ,@exps)))))
              ;((pair? exps)     `(let (($_ ,(car exps)))
              ;                    ,(dummy-bind (cdr exps))))))
          (dummy-bind (cdr exp)))))
    (define-syntax cond-expand
      (er-macro-transformer
        ;; Based on the cond-expand macro from Chibi scheme
        (lambda (expr rename compare)
          (define (_library-exists? import . ext)
            (file-exists?
              (_lib:import->filename 
                (_lib:import->library-name import)
                (if (null? ext) ".sld" (car ext)))))
          (define (_lib:import->filename import . ext)
            (let* ((file-ext 
                    (if (null? ext)
                        ".sld"
                        (car ext)))
                   (filename*
                    (string-append
                      (apply
                        string-append
                        (map 
                          (lambda (i) 
                            (string-append 
                              "/" 
                              (cond
                                ((symbol? i) (symbol->string i))
                                ((number? i) (number->string i))
                                (else (error "Unexpected type in import set")))))
                          import))
                      file-ext))
                   (filename
                     (substring filename* 1 (string-length filename*))))
              (if (or (equal? 'scheme (car import))
                      (equal? 'srfi   (car import))
                      (equal? 'cyclone (car import)))
                (string-append (Cyc-installation-dir 'sld) "/" filename) ;; Built-in library
                filename)))
          (define (_lib:import->library-name import)
            (cond
              ((and (pair? import)
                    (or (equal? 'only   (car import))
                        (equal? 'except (car import))
                        (equal? 'prefix (car import))
                        (equal? 'rename (car import))))
               (_lib:import->library-name 
                 (cadr import)))
              (else
               import)))
          (define (check x)
            (if (pair? x)
                (case (car x)
                  ((and) (every check (cdr x)))
                  ((or) (any check (cdr x)))
                  ((not) (not (check (cadr x))))
                  ((library) (_library-exists? (cadr x))) ;(eval `(find-module ',(cadr x)) (%meta-env)))
                  (else (error "cond-expand: bad feature" x)))
                (memq x (features))))
          (let expand ((ls (cdr expr)))
            (cond ((null? ls))  ; (error "cond-expand: no expansions" expr)
                  ((not (pair? (car ls))) (error "cond-expand: bad clause" (car ls)))
                  ((eq? 'else (caar ls)) ;(identifier->symbol (caar ls)))
                   (if (pair? (cdr ls))
                       (error "cond-expand: else in non-final position")
                       `(,(rename 'begin) ,@(cdar ls))))
                  ((check (caar ls)) `(,(rename 'begin) ,@(cdar ls)))
                  (else (expand (cdr ls))))))))
    (define-syntax cond
      (er-macro-transformer
          (lambda (expr rename compare)
            (if (null? (cdr expr))
                #f ;(if #f #f)
                ((lambda (cl)
                   (if (compare (rename 'else) (car cl))
                       (if (pair? (cddr expr))
                           (error "non-final else in cond" expr)
                           (list (cons (rename 'lambda) (cons '() (cdr cl)))))
                       (if (if (null? (cdr cl)) #t (compare (rename '=>) (cadr cl)))
                           (list (list (rename 'lambda) (list (rename 'tmp))
                                       (list (rename 'if) (rename 'tmp)
                                             (if (null? (cdr cl))
                                                 (rename 'tmp)
                                                 (list (car (cddr cl)) (rename 'tmp)))
                                             (cons (rename 'cond) (cddr expr))))
                                 (car cl))
                           (list (rename 'if)
                                 (car cl)
                                 (list (cons (rename 'lambda) (cons '() (cdr cl))))
                                 (cons (rename 'cond) (cddr expr))))))
                 (cadr expr))))))
    (define-syntax case
      (er-macro-transformer
          (lambda (expr rename compare)
            (define (body exprs)
              (cond
               ((null? exprs)
                (rename 'tmp))
               ((compare (rename '=>) (car exprs))
                `(,(cadr exprs) ,(rename 'tmp)))
               (else
                `(,(rename 'begin) ,@exprs))))
            (define (agg-cond tmp-sym lis)
              (if (null? lis)
                  #f
                  `(if (eq? ,tmp-sym (,(rename 'quote) ,(car lis)))
                       #t
                       ,(agg-cond tmp-sym (cdr lis)))))
            (define (clause ls)
              (cond
               ((null? ls) #f)
               ((compare (rename 'else) (caar ls))
                (body (cdar ls)))
               ((and (pair? (car (car ls))) (null? (cdr (car (car ls)))))
                `(,(rename 'if) (,(rename 'eqv?) ,(rename 'tmp)
                                 (,(rename 'quote) ,(car (caar ls))))
                  ,(body (cdar ls))
                  ,(clause (cdr ls))))
               (else
                `(,(rename 'if) 
                      ,(agg-cond (rename 'tmp) (caar ls))
                      ;(,(rename 'memv) ,(rename 'tmp)
                      ; (,(rename 'quote) ,(caar ls)))
                  ,(body (cdar ls))
                  ,(clause (cdr ls))))))
            `(let ((,(rename 'tmp) ,(cadr expr)))
               ,(clause (cddr expr))))))
    (define-syntax when
      (er-macro-transformer
        (lambda (exp rename compare)
          (if (null? (cdr exp)) (error "empty when" exp))
          (if (null? (cddr exp)) (error "no when body" exp))
          `(if ,(cadr exp)
               ((lambda () ,@(cddr exp)))
               #f))))
    (define-syntax unless
      (er-macro-transformer
        (lambda (exp rename compare)
          (if (null? (cdr exp)) (error "empty unless" exp))
          (if (null? (cddr exp)) (error "no unless body" exp))
          `(if ,(cadr exp)
               #f
               ((lambda () ,@(cddr exp)))))))
  (define-syntax do
    (er-macro-transformer
     (lambda (expr rename compare)
       (let* ((body
               `(,(rename 'begin)
                 ,@(cdr (cddr expr))
                 (,(rename 'lp)
                  ,@(map (lambda (x)
                           (if (pair? (cddr x))
                               (if (pair? (cdr (cddr x)))
                                   (error "too many forms in do iterator" x)
                                   (car (cddr x)))
                               (car x)))
                         (cadr expr)))))
              (check (car (cddr expr)))
              (wrap
               (if (null? (cdr check))
                   `(,(rename 'let) ((,(rename 'tmp) ,(car check)))
                     (,(rename 'if) ,(rename 'tmp)
                      ,(rename 'tmp)
                      ,body))
                   `(,(rename 'if) ,(car check)
                     (,(rename 'begin) ,@(cdr check))
                     ,body))))
         `(,(rename 'let) ,(rename 'lp)
           ,(map (lambda (x) (list (car x) (cadr x))) (cadr expr))
           ,wrap)))))
    (define-syntax quasiquote
      (er-macro-transformer
        ;; Based on the quasiquote macro from Chibi scheme
        (lambda (expr rename compare)
          (define (qq x d)
            (cond
             ((pair? x)
              (cond
               ((compare (rename 'unquote) (car x))
                (if (<= d 0)
                    (cadr x)
                    (list (rename 'list) (list (rename 'quote) 'unquote)
                          (qq (cadr x) (- d 1)))))
               ((compare (rename 'unquote-splicing) (car x))
                (if (<= d 0)
                    (list (rename 'cons) (qq (car x) d) (qq (cdr x) d))
                    (list (rename 'list) (list (rename 'quote) 'unquote-splicing)
                          (qq (cadr x) (- d 1)))))
               ((compare (rename 'quasiquote) (car x))
                (list (rename 'list) (list (rename 'quote) 'quasiquote)
                      (qq (cadr x) (+ d 1))))
               ((and (<= d 0) (pair? (car x))
                     (compare (rename 'unquote-splicing) (caar x)))
                (if (null? (cdr x))
                    (cadr (car x))
                    (list (rename 'append) (cadr (car x)) (qq (cdr x) d))))
               (else
                (list (rename 'cons) (qq (car x) d) (qq (cdr x) d)))))
             ((vector? x) (list (rename 'list->vector) (qq (vector->list x) d)))
             ((if (symbol? x) #t (null? x)) (list (rename 'quote) x))
             (else x)))
          (qq (cadr expr) 0))))

    (define-syntax syntax-error
      (er-macro-transformer
        (lambda (expr rename compare)
          (apply error (cdr expr)))))

    (define call-with-current-continuation call/cc)

    ;; Extended from r7rs definition to work in our Scheme
    (define values 
      (lambda args
        (if (and (not (null? args)) (null? (cdr args)))
            (car args)
            (cons (cons 'multiple 'values) args)))) 

    (define call-with-values
      (lambda (producer consumer)
        (let ((x (producer)))
          (if ;(magic? x)
              (and (pair? x) (equal? (car x) (cons 'multiple 'values)))
              (apply consumer (cdr x))
              (consumer x)))))

    (define (dynamic-wind before thunk after)
      (before)
      (let ((result (thunk)))
        (after)
        result)
      ;(call-with-values
      ;  thunk
      ;  (lambda (result) ;results
      ;    (after)
      ;    result)))
          ;(apply values results))))
    )
    (define (call-with-port port proc)
      (let ((result (proc port)))
        (close-port port)
        result))
    (define (Cyc-bin-op cmp x lst)
      (cond
        ((null? lst) #t)
        ((cmp x (car lst))
         (Cyc-bin-op cmp (car lst) (cdr lst)))
        (else #f)))
    (define (Cyc-bin-op-char cmp c cs)
      (Cyc-bin-op
        (lambda (x y) 
          (cmp (char->integer x) (char->integer y)))
        c
        cs))
    (define (char=?  c1 c2 . cs) (Cyc-bin-op-char =  c1 (cons c2 cs)))
    (define (char<?  c1 c2 . cs) (Cyc-bin-op-char <  c1 (cons c2 cs)))
    (define (char>?  c1 c2 . cs) (Cyc-bin-op-char >  c1 (cons c2 cs)))
    (define (char<=? c1 c2 . cs) (Cyc-bin-op-char <= c1 (cons c2 cs)))
    (define (char>=? c1 c2 . cs) (Cyc-bin-op-char >= c1 (cons c2 cs)))
    ; TODO: char-ci predicates (in scheme/char library)


    (define (string=? str1 str2)  (equal? (string-cmp str1 str2) 0))
    (define (string<? str1 str2)  (<  (string-cmp str1 str2) 0))
    (define (string<=? str1 str2) (<= (string-cmp str1 str2) 0))
    (define (string>? str1 str2)  (>  (string-cmp str1 str2) 0))
    (define (string>=? str1 str2) (>= (string-cmp str1 str2) 0))
    ; TODO: generalize to multiple arguments: (define (string<? str1 str2 . strs)

    (define (member-helper obj lst cmp-proc)
     (cond 
       ((null? lst) #f)
       ((cmp-proc obj (car lst)) lst)
       (else (member-helper obj (cdr lst) cmp-proc))))
    (define (member obj lst . compare) 
        (if (pair? compare)
            (member-helper obj lst (car compare))
            (member-helper obj lst equal?)))
    ;(define (memq obj lst) (member-helper obj lst eq?))
    ;(define (memv obj lst) (member-helper obj lst eqv?))
    
    (define (assoc-helper obj lst cmp?)
     (cond 
       ((null? lst) #f)
       ((and (pair? (car lst))
             (cmp? obj (car (car lst))))
        (car lst))
       (else (assoc-helper obj (cdr lst) cmp?))))
      
    (define (assoc obj alist . compare)
        (if (pair? compare)
            (assoc-helper obj alist (car compare))
            (assoc-helper obj alist equal?)))
    ;(define (assq obj alist) (assoc-helper obj alist eq?))
    ;(define (assv obj alist) (assoc-helper obj alist eqv?))

    (define (foldl func accum lst)
      (if (null? lst)
        accum
        (foldl func (func (car lst) accum) (cdr lst))))
    (define (foldr func end lst)
      (if (null? lst)
        end
        (func (car lst) (foldr func end (cdr lst)))))
    (define-c _read-u8
      "(void *data, int argc, closure _, object k, object port)"
      " Cyc_io_read_u8(data, k, port);")
    (define-c _peek-u8
      "(void *data, int argc, closure _, object k, object port)"
      " Cyc_io_peek_u8(data, k, port);")
    (define-c _write-u8
      "(void *data, int argc, closure _, object k, object chr, object port)"
      " return_closcall1(data, k, Cyc_write_u8(data, chr, port));")
    (define (read-u8 . port)
      (if (null? port)
        (_read-u8 (current-input-port))
        (_read-u8 (car port))))
    (define (peek-u8 . port)
      (if (null? port)
        (_peek-u8 (current-input-port))
        (_peek-u8 (car port))))
    (define (write-u8 chr . port)
      (if (null? port)
        (_write-u8 chr (current-output-port))
        (_write-u8 chr (car port))))
    (define (peek-char . port)
      (if (null? port)
        (Cyc-peek-char (current-input-port))
        (Cyc-peek-char (car port))))
    (define (read-char . port)
      (if (null? port)
        (Cyc-read-char (current-input-port))
        (Cyc-read-char (car port))))
    (define (read-line . port)
      (if (null? port)
        (Cyc-read-line (current-input-port))
        (Cyc-read-line (car port))))
    (define (read-string k . opts)
      (let ((port (if (null? opts)
                      (current-input-port)
                      (car opts))))
        (if (eof-object? (peek-char port))
            (eof-object)
            (let loop ((acc '())
                       (i k)
                       (chr #f))
              (cond
               ((eof-object? chr)
                (list->string
                 (reverse acc)))
               ((zero? i)
                (list->string
                 (reverse
                  (if chr (cons chr acc) acc))))
               (else
                (loop (if chr (cons chr acc) acc)
                      (- i 1)
                      (read-char port))))))))
    (define (flush-output-port . port)
      (if (null? port)
        (Cyc-flush-output-port (current-output-port))
        (Cyc-flush-output-port (car port))))
    (define (write-string str . port)
      (if (null? port)
        (Cyc-display str (current-output-port))
        (Cyc-display str (car port))))
    (define (write-char char . port)
      (if (null? port)
        (Cyc-write-char char (current-output-port))
        (Cyc-write-char char (car port))))
    (define (newline . port) 
      (apply write-char (cons #\newline port)))
    (define (not x) (if x #f #t))
    (define-c list?
      "(void *data, int argc, closure _, object k, object o)"
      " return_closcall1(data, k, Cyc_is_list(o));"
      "(void *data, object ptr, object o)"
      " return Cyc_is_list(o);")
    (define (zero? n) (= n 0))
    (define (positive? n) (> n 0))
    (define (negative? n) (< n 0))
    ; append accepts a variable number of arguments, per R5RS. So a wrapper
    ; has been provided for the standard 2-argument version of (append).
    ;
    ; We return the given value if less than 2 arguments are given, and
    ; otherwise fold over each arg, appending it to its predecessor. 
    (define (append . lst)
      (define append-2
              (lambda (inlist alist)
                      (foldr (lambda (ap in) (cons ap in)) alist inlist)))
      (if (null? lst)
          lst
          (if (null? (cdr lst))
              (car lst)
              (foldl (lambda (a b) (append-2 b a)) (car lst) (cdr lst)))))
    (define (list . objs)  objs)
    (define (make-list k . fill)
      (letrec ((x (if (null? fill) 
                   #f
                   (car fill)))
               (make
                 (lambda (n obj)
                   (if (zero? n)
                   '()
                   (cons obj (make (- n 1) obj) )))))
      (make k x)))
    (define (list-copy lst)
      (foldr (lambda (x y) (cons x y)) '() lst))
    ;; Implementation of receive from SRFI 8
    (define-syntax receive
      (er-macro-transformer
       (lambda (expr rename compare)
        ;(if (or (not (pair? expr))
        ;        (< (length expr) 3))
        ;    (syntax-error "Invalid syntax for receive" expr))
        (let ((formals (cadr expr))
              (val-expr (caddr expr))
              (body (cdddr expr)))
          `(call-with-values 
             (lambda () ,val-expr)
             (lambda ,formals ,@body))))))
;
; for example:
; (call-with-values (lambda () (values 1 2)) (lambda (x y) (write `(,x ,y))))
; ==>(1 2)
;
;(receive (x y) (values 1 2) (write `(,x ,y)))
; ==>(1 2)
;

; Added the following support functions from SRFI 1
(define (car+cdr pair) (values (car pair) (cdr pair)))
(define (%cars+cdrs lists)
  (call-with-current-continuation
    (lambda (abort)
      (let recur ((lists lists))
        (if (pair? lists)
          (receive (list other-lists) (car+cdr lists)
            (if (null? list) (abort '() '()) ; LIST is empty -- bail out
              (receive (a d) (car+cdr list)
                (receive (cars cdrs) (recur other-lists)
                  (values (cons a cars) (cons d cdrs))))))
          (values '() '()))))))
; END support functions

    (define (map f lis1 . lists)
    ;  (check-arg procedure? f map-in-order)
      (if (pair? lists)
          (let recur ((lists (cons lis1 lists)))
            (receive (cars cdrs) (%cars+cdrs lists)
              (if (pair? cars)
                  (let ((x (apply f cars)))		; Do head first,
                    (cons x (recur cdrs)))		; then tail.
                  '())))
          ;; Fast path.
         (foldr (lambda (x y) (cons (f x) y)) '() lis1)))

    ;; Experimenting with faster versions of map, for-each
    (define (Cyc-map-loop-1 f lst)
      (if (null? lst)
        '()
       (cons (f (car lst)) (Cyc-map-loop-1 f (cdr lst)))))
    (define (Cyc-for-each-loop-1 f lst)
      (if (null? lst)
        '()
       (begin (f (car lst)) 
              (Cyc-for-each-loop-1 f (cdr lst)))))

    (define (for-each f lis1 . lists)
      (if (not (null? lis1))
        (if (pair? lists)
          (let recur ((lists (cons lis1 lists)))
            (receive (cars cdrs) (%cars+cdrs lists)
              (if (pair? cars)
                  (begin
                    (apply f cars)
                    (recur cdrs)))))
          ;; Fast path.
          ;(if (eq? 1 (length lis1))
          (if (null? (cdr lis1)) ;; O(1) instead of O(n) for length
            (f (car lis1))
            (begin (f (car lis1))
                   (for-each f (cdr lis1)))))))
    (define (list-tail lst k) 
      (if (zero? k)
        lst
        (list-tail (cdr lst) (- k 1))))
    (define (list-ref lst k)  (car (list-tail lst k)))
    (define (list-set! lst k obj)
      (let ((kth (list-tail lst k)))
        (set-car! kth obj)))
    (define (reverse lst)   (foldl cons '() lst))

    (define (vector . objs) (list->vector objs))
    (define (vector->list vec . opts)
      (letrec ((len (vector-length vec))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len))
               (loop (lambda (i lst)
                       (if (= i end)
                           (reverse lst)
                           (loop (+ i 1) 
                                 (cons (vector-ref vec i) lst))))))
        (loop start '())))
    (define (bytevector-copy bv . opts)
      (letrec ((len (bytevector-length bv))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len)))
        (Cyc-bytevector-copy bv start end)))
    (define (bytevector-copy! to at from . o)
      (let* ((start (if (pair? o) (car o) 0))
             (end (if (and (pair? o) (pair? (cdr o)))
                      (cadr o)
                      (bytevector-length from)))
             (limit (min end (+ start (- (bytevector-length to) at)))))
        (if (<= at start)
            (do ((i at (+ i 1)) (j start (+ j 1)))
                ((>= j limit))
              (bytevector-u8-set! to i (bytevector-u8-ref from j)))
            (do ((i (+ at (- end start 1)) (- i 1)) (j (- limit 1) (- j 1)))
                ((< j start))
              (bytevector-u8-set! to i (bytevector-u8-ref from j))))))
    (define (utf8->string bv . opts)
      (letrec ((len (bytevector-length bv))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len)))
        (Cyc-utf8->string bv start end)))
    (define (string->utf8 str . opts)
      (letrec ((len (string-length str))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len)))
        (Cyc-string->utf8 str start end)))
    (define (vector->string vec . opts)
      (let ((lst (apply vector->list (cons vec opts))))
        (list->string lst)))
    (define (string->list str . opts)
      (letrec ((len (string-length str))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len))
               (loop (lambda (i lst)
                       (if (= i end)
                           (reverse lst)
                           (loop (+ i 1) 
                                 (cons (string-ref str i) lst))))))
        (loop start '())))
    (define (string->vector str . opts)
      (list->vector
        (apply string->list (cons str opts))))
    (define (string-copy str . opts)
      (letrec ((len (string-length str))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len)))
        (substring str start end)))
    (define (string-copy! to at from . opts)
      (letrec ((len (string-length from))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len))
               (loop (lambda (i-at i-from)
                       (cond
                        ((= i-from end) to)
                        (else
                          (string-set! to i-at (string-ref from i-from))
                          (loop (+ i-at 1) (+ i-from 1)))))))
        (loop at start)))
    (define (string-fill! str fill . opts)
      ;; TODO: technically this is not per spec, because end references len.
      ;;       Should change to use letrec*
      (letrec ((len (string-length str))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len))
               (loop (lambda (i)
                       (cond
                        ((= i end) str)
                        (else
                          (string-set! str i fill)
                          (loop (+ i 1)))))))
        (loop start)))
    (define (string-map func str1 . strs)
      (list->string
        (apply map `(,func ,(string->list str1) ,@(map string->list strs)))))
    (define (string-for-each func str1 . strs)
      (apply for-each `(,func ,(string->list str1) ,@(map string->list strs))))
    (define (vector-map func vec1 . vecs)
      (list->vector
        (apply map `(,func ,(vector->list vec1) ,@(map vector->list vecs)))))
    (define (vector-for-each func vec1 . vecs)
      (apply for-each `(,func ,(vector->list vec1) ,@(map vector->list vecs))))
    (define (vector-append . vecs)
      (list->vector
        (apply append (map vector->list vecs))))
    (define (vector-copy vec . opts)
      (letrec ((len (vector-length vec))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len))
               (loop (lambda (i new-vec)
                       (cond
                        ((= i end)
                         new-vec)
                        (else
                           (vector-set! new-vec (- i start) (vector-ref vec i))
                           (loop (+ i 1) new-vec))))))
        (loop start (make-vector (- end start) #f))))
    ;; TODO: does not quite meet r7rs spec, should check if vectors overlap
    (define (vector-copy! to at from . opts)
      (letrec ((len (vector-length from))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len))
               (loop (lambda (i-at i-from)
                       (cond
                        ((= i-from end) to)
                        (else
                          (vector-set! to i-at (vector-ref from i-from))
                          (loop (+ i-at 1) (+ i-from 1)))))))
        (loop at start)))
    ;; TODO: this len/start/end/loop pattern is common, could use a macro for it
    (define (vector-fill! vec fill . opts)
      (letrec ((len (vector-length vec))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len))
               (loop (lambda (i)
                       (cond
                        ((= i end) vec)
                        (else
                          (vector-set! vec i fill)
                          (loop (+ i 1)))))))
        (loop start)))

    (define (boolean=? b1 b2 . bs)
      (Cyc-obj=? boolean? b1 (cons b2 bs)))
    (define (symbol=? sym1 sym2 . syms)
      (Cyc-obj=? symbol? sym1 (cons sym2 syms)))
    (define (Cyc-obj=? type? obj objs)
      (and
        (type? obj)
        (call/cc
          (lambda (return)
            (for-each 
              (lambda (o)
                (if (not (eq? o obj))
                  (return #f)))
              objs)
              #t))))

    (define (string . chars)
      (list->string chars))

    (define (make-string k . fill)
      (Cyc-make-string k (if (null? fill) #\space (car fill))))

    (define-c Cyc-make-string
      "(void *data, int argc, closure _, object k, object count, object fill)"
      " object s = NULL;
        char ch_buf[5];
        char_type c;
        int buflen, num_cp, len;
        Cyc_check_fixnum(data, count);
        if (!obj_is_char(fill)) {
          Cyc_rt_raise2(data, \"Expected character buf received\", fill);
        }
        c = obj_obj2char(fill);
        if (!c) {
          buflen = 1;
        } else {
          Cyc_utf8_encode_char(ch_buf, 5, c);
          buflen = strlen(ch_buf);
        }
        num_cp = obj_obj2int(count);
        len = num_cp * buflen;
        if (len >= MAX_STACK_OBJ) {
          int heap_grown;
          s = gc_alloc(((gc_thread_data *)data)->heap, 
                       sizeof(string_type) + len + 1,
                       boolean_f, // OK to populate manually over here
                       (gc_thread_data *)data, 
                       &heap_grown);
          ((string_type *) s)->hdr.mark = ((gc_thread_data *)data)->gc_alloc_color;
          ((string_type *) s)->hdr.grayed = 0;
          ((string_type *) s)->hdr.immutable = 0;
          ((string_type *) s)->tag = string_tag; 
          ((string_type *) s)->len = len;
          ((string_type *) s)->num_cp = num_cp;
          ((string_type *) s)->str = (((char *)s) + sizeof(string_type));
        } else {
          s = alloca(sizeof(string_type));
          ((string_type *)s)->hdr.mark = gc_color_red; 
          ((string_type *)s)->hdr.grayed = 0;
          ((string_type *)s)->hdr.immutable = 0;
          ((string_type *)s)->tag = string_tag; 
          ((string_type *)s)->len = len;
          ((string_type *)s)->num_cp = num_cp;
          ((string_type *)s)->str = alloca(sizeof(char) * (len + 1));
        }
        if (num_cp == 1) { /* Fast path */
          memset(((string_type *)s)->str, ch_buf[0], len);
        } else {
          char *buf = ((string_type *)s)->str;
          int bi, si, slen = buflen;
          for (bi = 0, si = 0; bi < len; bi++, si++) {
            buf[bi] = ch_buf[si % slen];
          }
        }
        ((string_type *)s)->str[len] = '\\0';
        return_closcall1(data, k, s);
      ")

    (define-syntax parameterize
      (syntax-rules ()
        ((parameterize
           ("step")
           ((param value p old new) ...)
           ()
           body)
         (let ((p param) ...)
           (let ((old (p))
                 ...
                 (new ((p '<param-convert>) value))
                 ...)
             (dynamic-wind
               (lambda () (p '<param-set!> new) ...)
               (lambda () . body)
               (lambda () (p '<param-set!> old) ...)))))
        ((parameterize
           ("step")
           args
           ((param value) . rest)
           body)
         (parameterize
           ("step")
           ((param value p old new) . args)
           rest
           body))
        ((parameterize ((param value) ...) . body)
         (parameterize
           ("step")
           ()
           ((param value) ...)
           body))))
    (define-c get-param-objs
      "(void *data, int argc, closure _, object k)"
      " gc_thread_data *thd = (gc_thread_data *)data;
        //Cyc_st_add(data, \"scheme/base.sld:get-param-objs\");
        return_closcall1(data, k, thd->param_objs); ")
    (define-c set-param-obj!
      "(void *data, int argc, closure _, object k, object obj)"
      " gc_thread_data *thd = (gc_thread_data *)data;
        make_pair(c, obj, thd->param_objs);
        thd->param_objs = &c;
        return_closcall1(data, k, &c); ")
    (define *parameter-id* 0)
    (define (make-parameter init . o)
      (let* ((converter
               (if (pair? o) (car o) (lambda (x) x)))
             (value (converter init))
             (key #f))
        ;; This is not thread safe!
        (set! key *parameter-id*)
        (set! *parameter-id* (+ *parameter-id* 1))
        ;;
        (set-param-obj! (cons key value))

        (lambda args
          (cond
            ((null? args)
             (let ((pobj (get-param-objs)))
              (cdr (assoc key pobj))))
            ((eq? (car args) '<param-set!>)
             (let ((cell (assoc key (get-param-objs))))
              (set-cdr! cell (cadr args))))
            ((eq? (car args) '<param-convert>)
             converter)
           (else
             (let ((cell (assoc key (get-param-objs))))
              (set-cdr! cell (converter (car args))))
           )))))
    (define current-output-port
      (make-parameter (Cyc-stdout)))
    (define current-input-port
      (make-parameter (Cyc-stdin)))
    (define current-error-port
      (make-parameter (Cyc-stderr)))
    ;; TODO: only a first-step, error objects need to be more robust
    (define (error-object? x) 
      (and (pair? x) 
           (string? (car x))))
    (define error-object-message car)
    (define error-object-irritants cdr)
    (define (error msg . args)
      (raise (cons msg args)))
    (define (raise obj)
      ((Cyc-current-exception-handler) 
        (cons 'raised (if (pair? obj) obj (list obj)))))
    (define (raise-continuable obj)
      ((Cyc-current-exception-handler) 
        (cons 'continuable (if (pair? obj) obj (list obj)))))
    ;; A simpler exception handler based on the one from Bigloo:
    ;; https://www-sop.inria.fr/indes/fp/Bigloo/doc/bigloo-17.html#g20889
    ;(define (with-handler handler body)
    (define-syntax with-handler
      (er-macro-transformer
        (lambda (exp rename compare)
          `(call/cc
             (lambda (k)
               (with-exception-handler
                 (lambda (obj)
                   (k (,(cadr exp) obj)))
                 (lambda ()
                   ,@(cddr exp))))))))
    (define (with-exception-handler handler thunk)
      (let ((result #f)
            (my-handler 
              (lambda (obj)
                (let ((result #f)
                      (continuable? (and (pair? obj) 
                                         (equal? (car obj) 'continuable))))
                  ;; Unregister this handler since it is no longer needed
                  (Cyc-remove-exception-handler)
                  (set! result (handler (cdr obj))) ;; Actual handler
                  (if continuable?
                      result
                      (error "exception handler returned"))))))
      ;; No cond-expand below, since this is part of our internal lib
      (Cyc-add-exception-handler my-handler)
      (set! result (thunk))
      (Cyc-remove-exception-handler) ; Only reached if no ex raised
      result))
    (define-c Cyc-add-exception-handler
      "(void *data, int argc, closure _, object k, object h)"
      " gc_thread_data *thd = (gc_thread_data *)data;
        make_pair(c, h, thd->exception_handler_stack);
        thd->exception_handler_stack = &c;
        return_closcall1(data, k, &c); ")
    (define-c Cyc-remove-exception-handler
      "(void *data, int argc, closure _, object k)"
      " gc_thread_data *thd = (gc_thread_data *)data;
        if (thd->exception_handler_stack) {
          thd->exception_handler_stack = cdr(thd->exception_handler_stack);
        }
        return_closcall1(data, k, thd->exception_handler_stack); ")

  ;; Simplified versions of every/any from SRFI-1
  (define (any pred lst)
    (let any* ((l (map pred lst)))
        (cond
          ((null? l) #f) ; Empty list
          ((car l)   #t) ; Done
          (else 
             (any* (cdr l))))))
  (define (every pred lst)
    (let every* ((l (map pred lst)))
        (cond
          ((null? l) #t) ; Empty list
          ((car l)
             (every* (cdr l)))
          (else 
             #f))))

  (define-c floor
    "(void *data, int argc, closure _, object k, object z)"
    " return_exact_double_op(data, k, floor, z); "
    "(void *data, object ptr, object z)"
    " return_exact_double_op_no_cps(data, ptr, floor, z);")
  (define-c ceiling
    "(void *data, int argc, closure _, object k, object z)"
    " return_exact_double_op(data, k, ceil, z); "
    "(void *data, object ptr, object z)"
    " return_exact_double_op_no_cps(data, ptr, ceil, z);")
  (define-c truncate
    "(void *data, int argc, closure _, object k, object z)"
    " return_exact_double_op(data, k, (int), z); "
    "(void *data, object ptr, object z)"
    " return_exact_double_op_no_cps(data, ptr, (int), z);")
  (define-c round
    "(void *data, int argc, closure _, object k, object z)"
    " return_exact_double_op(data, k, round, z); "
    "(void *data, object ptr, object z)"
    " return_exact_double_op_no_cps(data, ptr, round, z);")
  (define exact truncate)
  (define-c inexact
    "(void *data, int argc, closure _, object k, object z)"
    " return_inexact_double_or_cplx_op(data, k, (double), (double complex), z); "
    "(void *data, object ptr, object z)"
    " return_inexact_double_or_cplx_op_no_cps(data, ptr, (double), (double complex), z);")
  (define-c abs
    "(void *data, int argc, closure _, object k, object num)"
    " Cyc_check_num(data, num);
      if (obj_is_int(num)) {
        return_closcall1(data, k, obj_int2obj( labs( obj_obj2int(num))));
      } else if (is_object_type(num) && type_of(num) == bignum_tag){
        alloc_bignum(data, bn);
        mp_abs(&bignum_value(num), &bignum_value(bn));
        return_closcall1(data, k, bn);
      } else {
        make_double(d, fabs(((double_type *)num)->value));
        return_closcall1(data, k, &d);
      } ")
  ;; Apparently C % is actually the remainder, not modulus
  (define-c remainder
    "(void *data, int argc, closure _, object k, object num1, object num2)"
    " Cyc_remainder(data, k, num1, num2); ")
  ;; From chibi scheme. Cannot use C % operator
  (define (modulo a b)
    (let ((res (remainder a b)))
      (if (< b 0)
        (if (<= res 0) res (+ res b))
        (if (>= res 0) res (+ res b)))))
  (define (odd? num)   (= (modulo num 2) 1))
  (define (even? num)  (= (modulo num 2) 0))
  (define-c bignum?
    "(void *data, int argc, closure _, object k, object obj)"
    " return_closcall1(data, k, Cyc_is_bignum(obj)); ")
  (define-c bignum-sqrt
    "(void *data, int argc, closure _, object k, object obj)"
    " alloc_bignum(data, bn);
      if (MP_OKAY != mp_sqrt(&(bignum_value(obj)), &bignum_value(bn))) {
        Cyc_rt_raise2(data, \"Error computing sqrt\", obj);
      }
      return_closcall1(data, k, bn); ")
  ;; from mosh
  (define (exact-integer-sqrt k)
    (unless (and (exact? k)
                 (integer? k)
                 (not (negative? k)))
      (error "exact non-negative integer required" k))
    (let* ((s (if (bignum? k)
                  (bignum-sqrt k)
                  (exact (truncate (sqrt k)))))
           (r (- k (* s s))))
      (values s r)))
  (define-c sqrt
    "(void *data, int argc, closure _, object k, object z)"
    " return_inexact_double_op(data, k, sqrt, z);"
    "(void *data, object ptr, object z)"
    " return_inexact_double_op_no_cps(data, ptr, sqrt, z);")
  (define-c exact-integer?
    "(void *data, int argc, closure _, object k, object num)"
    " if (obj_is_int(num) || (num != NULL && !is_value_type(num) && 
                               (type_of(num) == integer_tag || 
                                type_of(num) == bignum_tag)))
        return_closcall1(data, k, boolean_t);
      return_closcall1(data, k, boolean_f); "
    "(void *data, object ptr, object num)"
    " if (obj_is_int(num) || (num != NULL && !is_value_type(num) && 
                               (type_of(num) == integer_tag || 
                                type_of(num) == bignum_tag)))
        return boolean_t;
      return boolean_f;")
  (define-c exact?
    "(void *data, int argc, closure _, object k, object num)"
    " Cyc_check_num(data, num);
      if (obj_is_int(num) || type_of(num) == integer_tag 
                          || type_of(num) == bignum_tag)
        return_closcall1(data, k, boolean_t);
      return_closcall1(data, k, boolean_f); "
    "(void *data, object ptr, object num)"
    " Cyc_check_num(data, num);
      if (obj_is_int(num) || type_of(num) == integer_tag 
                          || type_of(num) == bignum_tag)
        return boolean_t;
      return boolean_f;")
  (define (inexact? num) (not (exact? num)))
  (define-c complex?
    "(void *data, int argc, closure _, object k, object z)"
    " return_closcall1(data, k, Cyc_is_complex(z)); "
    "(void *data, object ptr, object z)"
    " return Cyc_is_complex(z); ")
  (define rational? number?)
  (define (max first . rest) (foldl (lambda (old new) (if (> old new) old new)) first rest))
  (define (min first . rest) (foldl (lambda (old new) (if (< old new) old new)) first rest))
  ; Implementations of gcd and lcm using Euclid's algorithm
  ;
  ; Also note that each form is written to accept either 0 or
  ; 2 arguments, per R5RS. This could probably be generalized
  ; even further, if necessary.
  ;
  (define gcd gcd/entry)
  (define lcm lcm/entry)
  ; Main GCD algorithm
  (define (gcd/main a b)
    (if (= b 0)
      (abs a)
      (gcd/main b (modulo a b))))

  ; A helper function to reduce the input list
  (define (gcd/entry . nums)
    (if (eqv? nums '())
      0
      (foldl gcd/main (car nums) (cdr nums))))

  ; Main LCM algorithm
  (define (lcm/main a b)
    (abs (/ (* a b) (gcd/main a b))))

  ; A helper function to reduce the input list
  (define (lcm/entry . nums)
    (if (eqv? nums '())
      1
      (foldl lcm/main (car nums) (cdr nums))))
  ;; END gcd lcm

  ;; Placeholders
  (define (denominator n) 1)
  (define (numerator n) n)

  (define (quotient x y)
    (truncate (/ x y)))

  (define truncate-quotient quotient)
  (define truncate-remainder remainder)
  (define (truncate/ n m)
    (values (truncate-quotient n m) (truncate-remainder n m)))
  
  (define (floor-quotient n m)
    (let ((res (floor (/ n m))))
      (if (and (exact? n) (exact? m))
          (exact res)
          res)))
  (define (floor-remainder n m)
    (- n (* m (floor-quotient n m))))
  (define (floor/ n m)
    (values (floor-quotient n m) (floor-remainder n m)))
  (define (square z) (* z z))
  (define-c expt
    "(void *data, int argc, closure _, object k, object z1, object z2)"
    " Cyc_expt(data, k, z1, z2); ")
  (define-c eof-object
    "(void *data, int argc, closure _, object k)"
    " return_closcall1(data, k, Cyc_EOF); "
    "(void *data, object ptr)"
    " return Cyc_EOF;")
  (define-c input-port?
    "(void *data, int argc, closure _, object k, object port)"
    " port_type *p = (port_type *)port;
      if (boolean_f == Cyc_is_port(port)) {
        return_closcall1(data, k, boolean_f);
      }
      return_closcall1(
        data, 
        k, 
       ((p->mode == 1) ? boolean_t : boolean_f)); ")
  (define-c output-port?
    "(void *data, int argc, closure _, object k, object port)"
    " port_type *p = (port_type *)port;
      if (boolean_f == Cyc_is_port(port)) {
        return_closcall1(data, k, boolean_f);
      }
      return_closcall1(
        data, 
        k, 
       ((p->mode == 0) ? boolean_t : boolean_f)); ")
  (define-c input-port-open?
    "(void *data, int argc, closure _, object k, object port)"
    " port_type *p = (port_type *)port;
      if (boolean_f == Cyc_is_port(port)) {
        return_closcall1(data, k, boolean_f);
      }
      return_closcall1(
        data, 
        k, 
       ((p->mode == 1 && p->fp != NULL) ? boolean_t : boolean_f)); ")
  (define-c output-port-open?
    "(void *data, int argc, closure _, object k, object port)"
    " port_type *p = (port_type *)port;
      if (boolean_f == Cyc_is_port(port)) {
        return_closcall1(data, k, boolean_f);
      }
      return_closcall1(
        data, 
        k, 
       ((p->mode == 0 && p->fp != NULL) ? boolean_t : boolean_f)); ")
  (define-c open-input-string
    "(void *data, int argc, closure _, object k, object str)"
    " port_type *p = Cyc_io_open_input_string(data, str);
      return_closcall1(data, k, p); ")
  (define-c open-output-string
    "(void *data, int argc, closure _, object k)"
    " port_type *p = Cyc_io_open_output_string(data);
      return_closcall1(data, k, p); ")
  (define-c get-output-string
    "(void *data, int argc, closure _, object k, object port)"
    " Cyc_io_get_output_string(data, k, port);
    ")
  (define-c get-output-bytevector
    "(void *data, int argc, closure _, object k, object port)"
    " Cyc_io_get_output_bytevector(data, k, port);
    ")
  (define-c open-input-bytevector
    "(void *data, int argc, closure _, object k, object bv)"
    " port_type *p = Cyc_io_open_input_bytevector(data, bv);
      return_closcall1(data, k, p); ")
  (define open-output-bytevector open-output-string)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; syntax-rules
(define identifier? symbol?)
;(define (identifier->symbol obj) obj)
(define (find-tail pred ls)
  (and (pair? ls) (if (pred (car ls)) ls (find-tail pred (cdr ls)))))

(define (find pred ls)
  (cond ((find-tail pred ls) => car) (else #f)))
(define (cons-source kar kdr source)
  (cons kar kdr))

(define-syntax syntax-rules
  (er-macro-transformer
   (lambda (expr rename compare)
;(Cyc-write `(syntax-rules expand ,expr) (current-output-port))
;(Cyc-display "\n"  (current-output-port))
     (let ((ellipsis-specified? (identifier? (cadr expr)))
           (count 0)
           (_er-macro-transformer (rename 'er-macro-transformer))
           (_lambda (rename 'lambda))      (_let (rename 'let))
           (_begin (rename 'begin))        (_if (rename 'if))
           (_and (rename 'and))            (_or (rename 'or))
           (_eq? (rename 'eq?))            (_equal? (rename 'equal?))
           (_car (rename 'car))            (_cdr (rename 'cdr))
           (_cons (rename 'cons))          (_pair? (rename 'pair?))
           (_null? (rename 'null?))        (_expr (rename 'expr))
           (_rename (rename 'rename))      (_compare (rename 'compare))
           (_quote (rename 'quote)) (_apply (rename 'apply))
           ;(_quote (rename 'syntax-quote)) (_apply (rename 'apply))
           (_append (rename 'append))      (_map (rename 'map))
           (_vector? (rename 'vector?))    (_list? (rename 'list?))
           (_len (rename'len))             (_length (rename 'length))
           (_- (rename '-))   (_>= (rename '>=))   (_error (rename 'error))
           (_ls (rename 'ls)) (_res (rename 'res)) (_i (rename 'i))
           (_reverse (rename 'reverse))
           (_vector->list (rename 'vector->list))
           (_list->vector (rename 'list->vector))
           (_cons3 (rename 'cons-source)))
       (define ellipsis (rename (if ellipsis-specified? (cadr expr) '...)))
       (define lits (if ellipsis-specified? (car (cddr expr)) (cadr expr)))
       (define forms (if ellipsis-specified? (cdr (cddr expr)) (cddr expr)))
       (define (next-symbol s)
         (set! count (+ count 1))
         (rename (string->symbol (string-append s (number->string count)))))
       (define (expand-pattern pat tmpl)
         (let lp ((p (cdr pat))
                  (x (list _cdr _expr))
                  (dim 0)
                  (vars '())
                  (k (lambda (vars)
                       (list _cons (expand-template tmpl vars) #f))))
;(Cyc-write (list 'PATTERN p 'vars vars) (current-output-port))
;(Cyc-display "\n"  (current-output-port))
           (let ((v (next-symbol "v.")))
             (list
              _let (list (list v x))
              (cond
               ((identifier? p)
                (if (any (lambda (l) (compare p l)) lits)
                    (list _and
                          (list _compare v (list _rename (list _quote p)))
                          (k vars))
                    (list _let (list (list p v)) (k (cons (cons p dim) vars)))))
               ((ellipsis? p)
                (cond
                 ((not (null? (cdr (cdr p))))
                  (cond
                   ((any (lambda (x) (and (identifier? x) (compare x ellipsis)))
                         (cddr p))
                    (error "multiple ellipses" p))
                   (else
                    (let ((len (length (cdr (cdr p))))
                          (_lp (next-symbol "lp.")))
                      `(,_let ((,_len (,_length ,v)))
                         (,_and (,_>= ,_len ,len)
                                (,_let ,_lp ((,_ls ,v)
                                             (,_i (,_- ,_len ,len))
                                             (,_res (,_quote ())))
                                  (,_if (,_>= 0 ,_i)
                                      ,(lp `(,(cddr p) 
                                             (,(car p) ,(car (cdr p))))
                                           `(,_cons ,_ls
                                                    (,_cons (,_reverse ,_res)
                                                            (,_quote ())))
                                           dim
                                           vars
                                           k)
                                      (,_lp (,_cdr ,_ls)
                                            (,_- ,_i 1)
                                            (,_cons3 (,_car ,_ls)
                                                     ,_res
                                                     ,_ls))))))))))
                 ((identifier? (car p))
                  (list _and (list _list? v)
                        (list _let (list (list (car p) v))
                              (k (cons (cons (car p) (+ 1 dim)) vars)))))
                 (else
                  (let* ((w (next-symbol "w."))
                         (_lp (next-symbol "lp."))
                         (new-vars (all-vars (car p) (+ dim 1)))
                         (ls-vars (map (lambda (x)
                                         (next-symbol
                                          (string-append
                                           (symbol->string
                                            (car x))
                                            ;(identifier->symbol (car x)))
                                           "-ls")))
                                       new-vars))
                         (once
                          (lp (car p) (list _car w) (+ dim 1) '()
                              (lambda (_)
                                (cons
                                 _lp
                                 (cons
                                  (list _cdr w)
                                  (map (lambda (x l)
                                         (list _cons (car x) l))
                                       new-vars
                                       ls-vars)))))))
                    (list
                     _let
                     _lp (cons (list w v)
                               (map (lambda (x) (list x (list _quote '()))) ls-vars))
                     (list _if (list _null? w)
                           (list _let (map (lambda (x l)
                                             (list (car x) (list _reverse l)))
                                           new-vars
                                           ls-vars)
                                 (k (append new-vars vars)))
                           (list _and (list _pair? w) once)))))))
               ((pair? p)
                (list _and (list _pair? v)
                      (lp (car p)
                          (list _car v)
                          dim
                          vars
                          (lambda (vars)
                            (lp (cdr p) (list _cdr v) dim vars k)))))
               ((vector? p)
                (list _and
                      (list _vector? v)
                      (lp (vector->list p) (list _vector->list v) dim vars k)))
               ((null? p) (list _and (list _null? v) (k vars)))
               (else (list _and (list _equal? v p) (k vars))))))))
       (define (ellipsis-escape? x) (and (pair? x) (compare ellipsis (car x))))
       (define (ellipsis? x)
         (and (pair? x) (pair? (cdr x)) (compare ellipsis (cadr x))))
       (define (ellipsis-depth x)
         (if (ellipsis? x)
             (+ 1 (ellipsis-depth (cdr x)))
             0))
       (define (ellipsis-tail x)
         (if (ellipsis? x)
             (ellipsis-tail (cdr x))
             (cdr x)))
       (define (all-vars x dim)
         (let lp ((x x) (dim dim) (vars '()))
           (cond ((identifier? x)
                  (if (any (lambda (lit) (compare x lit)) lits)
                      vars
                      (cons (cons x dim) vars)))
                 ((ellipsis? x) (lp (car x) (+ dim 1) (lp (cddr x) dim vars)))
                 ((pair? x) (lp (car x) dim (lp (cdr x) dim vars)))
                 ((vector? x) (lp (vector->list x) dim vars))
                 (else vars))))
       (define (free-vars x vars dim)
         (let lp ((x x) (free '()))
           (cond
            ((identifier? x)
             (if (and (not (memq x free))
                      (cond ((assq x vars) => (lambda (cell) (>= (cdr cell) dim)))
                            (else #f)))
                 (cons x free)
                 free))
            ((pair? x) (lp (car x) (lp (cdr x) free)))
            ((vector? x) (lp (vector->list x) free))
            (else free))))
       (define (expand-template tmpl vars)
         (let lp ((t tmpl) (dim 0))
;(Cyc-write (list 't t) (current-output-port))
;(Cyc-display "\n" (current-output-port))
;(Cyc-write (list 'vars vars 'TMPL tmpl ) (current-output-port))
;(Cyc-display "\n"  (current-output-port))
           (cond
            ((identifier? t)
;(Cyc-write (list 't t 'vars vars) (current-output-port))
;(Cyc-display "\n"  (current-output-port))
             (cond
              ((find (lambda (v) (eq? t (car v))) vars)
               => (lambda (cell)
                    (if (<= (cdr cell) dim)
                        t
                        (error "too few ...'s"))))
              (else
               (list _rename (list _quote t)))))
            ((pair? t)
             (cond
              ((ellipsis-escape? t)
               (list _quote
                     (if (pair? (cdr t))
                         (if (pair? (cddr t)) (cddr t) (cadr t))
                         (cdr t))))
              ((ellipsis? t)
               (let* ((depth (ellipsis-depth t))
                      (ell-dim (+ dim depth))
                      (ell-vars (free-vars (car t) vars ell-dim)))
                 (cond
                  ((null? ell-vars)
                   (error "too many ...'s"))
                  ((and (null? (cdr (cdr t))) (identifier? (car t)))
                   ;; shortcut for (var ...)
                   (lp (car t) ell-dim))
                  (else
                   (let* ((once (lp (car t) ell-dim))
                          (nest (if (and (null? (cdr ell-vars))
                                         (identifier? once)
                                         (eq? once (car vars)))
                                    once ;; shortcut
                                    (cons _map
                                          (cons (list _lambda ell-vars once)
                                                ell-vars))))
                          (many (do ((d depth (- d 1))
                                     (many nest
                                           (list _apply _append many)))
                                    ((= d 1) many))))
                     (if (null? (ellipsis-tail t))
                         many ;; shortcut
                         (list _append many (lp (ellipsis-tail t) dim))))))))
              (else (list _cons3 (lp (car t) dim) (lp (cdr t) dim) (list _quote t)))))
            ((vector? t) (list _list->vector (lp (vector->list t) dim)))
            ((null? t) (list _quote '()))
            (else t))))
       (list
        _er-macro-transformer
        (list _lambda (list _expr _rename _compare)
;(Cyc-write `(syntax-rules expand ,_expr) (current-output-port))
;(Cyc-display "\n"  (current-output-port))
;(list 'Cyc-write (list 'syntax-rules 'expand _expr) (list 'current-output-port))
;(list 'Cyc-display "\n"  (list 'current-output-port))
              (list
               _car
               (cons
                _or
                (append
                 (map
                  (lambda (clause) (expand-pattern (car clause) (cadr clause)))
                  forms)
                 (list
                  (list _cons
                        (list _error "no expansion for"
                             _expr ; (list (rename 'strip-syntactic-closures) _expr)
                              )
                        #f)))))))))))

(define-syntax letrec*
  (syntax-rules ()
    ((letrec* ((var val) ...) . body)
     (let () (define var val) ... . body))))

(define-syntax let*-values
  (syntax-rules ()
    ((let*-values () . body)
     (begin . body))
    ((let*-values (((a) expr) . rest) . body)
     (let ((a expr)) (let*-values rest . body)))
    ((let*-values ((params expr) . rest) . body)
     (call-with-values (lambda () expr)
       (lambda params (let*-values rest . body))))))

#;(define-syntax let-values
  (syntax-rules ()
    ((let-values ("step") (binds ...) bind expr maps () () . body)
     (let*-values (binds ... (bind expr)) (let maps . body)))
    ((let-values ("step") (binds ...) bind old-expr maps () ((params expr) . rest) . body)
     (let-values ("step") (binds ... (bind old-expr)) () expr maps params rest . body))
    ((let-values ("step") binds (bind ...) expr (maps ...) (x . y) rest . body)
     (let-values ("step") binds (bind ... tmp) expr (maps ... (x tmp)) y rest . body))
    ((let-values ("step") binds (bind ...) expr (maps ...) x rest . body)
     (let-values ("step") binds (bind ... . tmp) expr (maps ... (x tmp)) () rest . body))
    ((let-values ((params expr) . rest) . body)
     (let-values ("step") () () expr () params rest . body))
    ))

(define-syntax
  let-values
  (syntax-rules
    ()
    ((let-values (binding ...) body0 body1 ...)
     (let-values
       "bind"
       (binding ...)
       ()
       ((lambda () body0 body1 ...))))
       ;(begin body0 body1 ...)))
    ((let-values "bind" () tmps body)
     (let tmps body))
    ((let-values
       "bind"
       ((b0 e0) binding ...)
       tmps
       body)
     (let-values
       "mktmp"
       b0
       e0
       ()
       (binding ...)
       tmps
       body))
    ((let-values
       "mktmp"
       ()
       e0
       args
       bindings
       tmps
       body)
     (call-with-values
       (lambda () e0)
       (lambda args
         (let-values "bind" bindings tmps body))))
    ((let-values
       "mktmp"
       (a . b)
       e0
       (arg ...)
       bindings
       (tmp ...)
       body)
     (let-values
       "mktmp"
       b
       e0
       (arg ... x)
       bindings
       (tmp ... (a x))
       body))
    ((let-values
       "mktmp"
       a
       e0
       (arg ...)
       bindings
       (tmp ...)
       body)
     (call-with-values
       (lambda () e0)
       ;(lambda (arg ... x)
       (lambda (arg ... . x)
         (let-values "bind" bindings (tmp ... (a x)) body))))))

(define-syntax guard
  (syntax-rules ()
    ((guard (var clause ...) e1 e2 ...)
     ((call-with-current-continuation
       (lambda (guard-k)
         (with-exception-handler
          (lambda (condition)
            ((call-with-current-continuation
              (lambda (handler-k)
                (guard-k
                 (lambda ()
                   (let ((var condition))      ; clauses may SET! var
                     (guard-aux (handler-k (lambda ()
                                             (raise-continuable condition)))
                                clause ...))))))))
          (lambda ()
            (let ((res (begin e1 e2 ...)))
              (guard-k (lambda () res)))))))))))

(define-syntax guard-aux
  (syntax-rules (else =>)
    ((guard-aux reraise (else result1 result2 ...))
     (begin result1 result2 ...))
    ((guard-aux reraise (test => result))
     (let ((temp test))
       (if temp (result temp) reraise)))
    ((guard-aux reraise (test => result) clause1 clause2 ...)
     (let ((temp test))
       (if temp (result temp) (guard-aux reraise clause1 clause2 ...))))
    ((guard-aux reraise (test))
     (or test reraise))
    ((guard-aux reraise (test) clause1 clause2 ...)
     (or test (guard-aux reraise clause1 clause2 ...)))
    ((guard-aux reraise (test result1 result2 ...))
     (if test (begin result1 result2 ...) reraise))
    ((guard-aux reraise (test result1 result2 ...) clause1 clause2 ...)
     (if test
         (begin result1 result2 ...)
         (guard-aux reraise clause1 clause2 ...)))))

;; Record-type definitions
(define record-marker (list 'record-marker))
(define (register-simple-type name parent field-tags)
  (vector record-marker name field-tags)
  ;(let ((new (make-vector 3 #f)))
  ;  (vector-set! new 0 record-marker)
  ;  (vector-set! new 1 name)
  ;  (vector-set! new 2 field-tags)
  ;  new)
)
(define (make-type-predicate pred name)
  (lambda (obj)
    (and (vector? obj)
         (equal? (vector-ref obj 0) record-marker)
         (equal? (vector-ref obj 1) name))))
(define (make-constructor make name)
  (lambda args
    (let* ((field-tags (vector-ref name 2))
           (field-values (make-vector (length field-tags) #f))
          )
      (vector record-marker name field-values))))
(define (make-constructor/args make name)
  (lambda args
    (let* ((field-tags (vector-ref name 2))
           (field-values (list->vector args)))
      (when (not (equal? (length field-tags) (length args)))
        (error "invalid number of arguments passed to record type constructor" args))
      (vector record-marker name field-values))))
(define (type-slot-offset name sym)
  (let ((field-tags (vector-ref name 2)))
    (_list-index sym field-tags)))
(define (slot-set! name obj idx val)
  (let ((vec obj)) ;; TODO: get actual slots from obj
    (vector-set! (vector-ref vec 2) idx val)))
(define (slot-ref name obj field)
  (let* ((idx (cond 
                ((symbol? field)
                 (type-slot-offset name field))
                (else
                  field)))) ;; Assumes field is a number
  (vector-ref (vector-ref obj 2) idx)))
(define (make-getter sym name idx)
  (lambda (obj)
    (vector-ref (vector-ref obj 2) idx)))
(define (make-setter sym name idx)
  (lambda (obj val)
    (vector-set! (vector-ref obj 2) idx val)))

;; Find index of element in list, or #f if not found
(define _list-index
  (lambda (e lst1)
    (let lp ((lis lst1) (n 0))
      (and (not (null? lis))
           (if (eq? e (car lis)) n (lp (cdr lis) (+ n 1)))))))

(define (record? obj)
  (and (vector? obj)
       (> (vector-length obj) 0)
       (equal? record-marker (vector-ref obj 0))))

(define (is-a? obj rtype)
  (and (record? obj)
       (record? rtype)
       (equal? (vector-ref obj 1) rtype)))

(define-syntax define-record-type
  (er-macro-transformer
   (lambda (expr rename compare)
     (let* ((name+parent (cadr expr))
            (name (if (pair? name+parent) (car name+parent) name+parent))
            (parent (and (pair? name+parent) (cadr name+parent)))
            (name-str (symbol->string name)) ;(identifier->symbol name)))
            (procs (cddr expr))
            (make (caar procs))
            (make-fields (cdar procs))
            (pred (cadr procs))
            (fields (cddr procs))
            (_define (rename 'define))
            (_lambda (rename 'lambda))
            (_let (rename 'let))
            (_register (rename 'register-simple-type))
            (_slot-set! (rename 'slot-set!))
            (_type_slot_offset (rename 'type-slot-offset)))
       ;; catch a common mistake
       (if (eq? name make)
           (error "same binding for record rtd and constructor" name))
       `(,(rename 'begin)
         ;; type
         (,_define ,name (,_register 
                          ,name-str 
                          ,parent 
                          ',(map car fields)))
         ;; predicate
         (,_define ,pred (,(rename 'make-type-predicate)
                          ,pred ;(symbol->string pred) ;(identifier->symbol pred))
                          ,name))
         ;; fields
         ,@(map (lambda (f)
                  (and (pair? f) (pair? (cdr f))
                       `(,_define ,(cadr f)
                          (,(rename 'make-getter)
                           ,(symbol->string
                             (cadr f)
                             ;(identifier->symbol (cadr f))
                            )
                           ,name
                           (,_type_slot_offset ,name ',(car f))))))
                fields)
         ,@(map (lambda (f)
                  (and (pair? f) (pair? (cdr f)) (pair? (cddr f))
                       `(,_define ,(car (cddr f))
                          (,(rename 'make-setter)
                           ,(symbol->string
                             (car (cddr f))
                             ;(identifier->symbol (car (cddr f)))
                            )
                           ,name
                           (,_type_slot_offset ,name ',(car f))))))
                fields)
         ;; constructor
         (,_define ,make
            (,_let ((%make (,(rename 'make-constructor/args)
                            ,(symbol->string make) ;(identifier->symbol make))
                            ,name)))
              (,_lambda ,make-fields
                (%make ,@make-fields))))
         ; Possible alternate version that inlines make-constructor/args
         ;(,_define ,make
         ;   (,_lambda ,make-fields
         ;     (,(rename 'vector)
         ;     ',record-marker
         ;      ,name
         ;      (,(rename 'vector)
         ;       ,@make-fields))))
  )))))
))
