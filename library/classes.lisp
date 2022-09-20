(coalton-library/utils:defstdlib-package #:coalton-library/classes
  (:use
   #:coalton)
  (:export
   #:Addressable #:eq?)
  (:export
   #:Eq #:==
   #:Num #:+ #:- #:* #:fromInt)
  (:export
   #:Tuple
   #:Optional #:Some #:None
   #:Result #:Ok #:Err
   #:Eq #:==
   #:Ord #:LT #:EQ #:GT
   #:<=> #:> #:< #:>= #:<=
   #:max
   #:min
   #:Num #:+ #:- #:* #:fromInt
   #:Semigroup #:<>
   #:Monoid #:mempty
   #:Functor #:map
   #:Applicative #:pure #:liftA2
   #:Monad #:>>=
   #:>>
   #:MonadFail #:fail
   #:Alternative #:alt #:empty
   #:Foldable #:fold #:foldr #:mconcat
   #:Traversable #:traverse
   #:sequence
   #:Into
   #:TryInto
   #:Iso
   #:error
   #:Unwrappable #:unwrap-or-else #:with-default #:unwrap #:expect #:as-optional
   #:Hash #:hash
   #:combine-hashes
   #:define-sxhash-hasher))

#+coalton-release
(cl:declaim #.coalton-impl:*coalton-optimize-library*)

(in-package #:coalton-library/classes)

(coalton-toplevel
  (define-class (Addressable :obj)
    "Types for which object identity is meaningful.

`eq?` should correspond exactly to the Common Lisp function `eq`, testing object identity (aka pointer
equality).

The compiler will auto-generate instances of `Addressable` for types which specify `repr :enum` or `repr
:lisp`.

Types with `repr :native` may manually implement `Addressable`, but programmers are encouraged to check the
[Common Lisp Hyperspec](http://www.lispworks.com/documentation/HyperSpec/Body/f_eq.htm) to determine what
guarantees, if any, are imposed on the behavior of `eq`. Types represented by `cl:character` or
`cl:number` (or sub- or supertypes thereof) should not implement `Addressable`, as those objects may be
implicitly copied.

No other types may implement `Addressable`. Defining an `Addressable` instance manually for a type which does
not specify `repr :native` will error. If you need an `Addressable` instance for a non-`repr :native` type,
specify `repr :lisp`."
    (eq? (:obj -> :obj -> Boolean)))

  (define-class (Eq :a)
    "Types which have equality defined."
    (== (:a -> :a -> Boolean)))

  (define-class ((Eq :a) => (Num :a))
    "Types which have numeric operations defined."
    (+ (:a -> :a -> :a))
    (- (:a -> :a -> :a))
    (* (:a -> :a -> :a))
    (fromInt (Integer -> :a))))

(in-package #:coalton)

(coalton-toplevel
  (repr :enum)
  (define-type Unit Unit)

  (repr :native cl:t)
  (define-type Void)

  ;; Boolean is an early type
  (declare True Boolean)
  (define True (lisp Boolean ()  cl:t))

  (declare False Boolean)
  (define False (lisp Boolean ()  cl:nil))

  ;; List is an early type
  (declare Cons (:a -> (List :a) -> (List :a)))
  (define (Cons x xs)
    (lisp (List :a) (x xs)
      (cl:cons x xs)))

  (declare Nil (List :a))
  (define Nil
    (lisp (List :a) ()
      cl:nil)))

(in-package #:coalton-library/classes)

(coalton-toplevel
 
  (define-type (Tuple :a :b)
    "A heterogeneous collection of items."
    (Tuple :a :b))

  (define-type (Optional :a)
    "Represents something that may not have a value."
    (Some :a)
    None)

  (define-type (Result :bad :good)
    "Represents something that may have failed."
    ;; We write (Result :bad :good) instead of (Result :good :bad)
    ;; because of the limitations of how we deal with higher-kinded
    ;; types; we want to implement Functor on this.
    (Ok :good)
    (Err :bad))

  (define-instance (Eq Unit)
    (define (== _ _) True))

  ;;
  ;; Ord
  ;;

  (repr :enum)
  (define-type Ord
    LT
    EQ
    GT)

  (define-instance (Eq Ord)
    (define (== a b)
      (match (Tuple a b)
        ((Tuple (LT) (LT)) True)
        ((Tuple (EQ) (EQ)) True)
        ((Tuple (GT) (GT)) True)
        (_                 False))))

  (define-instance (Ord Ord)
    (define (<=> a b)
      (match (Tuple a b)
        ((Tuple (LT) (LT)) EQ)
        ((Tuple (LT) (EQ)) LT)
        ((Tuple (LT) (GT)) LT)
        ((Tuple (EQ) (LT)) GT)
        ((Tuple (EQ) (EQ)) EQ)
        ((Tuple (EQ) (GT)) LT)
        ((Tuple (GT) (LT)) GT)
        ((Tuple (GT) (EQ)) GT)
        ((Tuple (GT) (GT)) EQ))))

  (define-class ((Eq :a) => (Ord :a))
    "Types whose values can be ordered."
    (<=> (:a -> :a -> Ord)))

  (declare > (Ord :a => (:a -> :a -> Boolean)))
  (define (> x y)
    "Is X greater than Y?"
    (match (<=> x y)
      ((GT) True)
      (_ False)))

  (declare < (Ord :a => (:a -> :a -> Boolean)))
  (define (< x y)
    "Is X less than Y?"
    (match (<=> x y)
      ((LT) True)
      (_ False)))

  (declare >= (Ord :a => (:a -> :a -> Boolean)))
  (define (>= x y)
    "Is X greater than or equal to Y?"
    (match (<=> x y)
      ((LT) False)
      (_ True)))

  (declare <= (Ord :a => (:a -> :a -> Boolean)))
  (define (<= x y)
    "Is X less than or equal to Y?"
    (match (<=> x y)
      ((GT) False)
      (_ True)))

  (declare max (Ord :a => (:a -> :a -> :a)))
  (define (max x y)
    "Returns the greater element of X and Y."
    (if (> x y)
        x
        y))

  (declare min (Ord :a => (:a -> :a -> :a)))
  (define (min x y)
    "Returns the lesser element of X and Y."
    (if (< x y)
        x
        y))

  ;;
  ;; Haskell
  ;;

  (define-class (Semigroup :a)
    "Types with an associative binary operation defined."
    (<> (:a -> :a -> :a)))

  (define-class (Semigroup :a => (Monoid :a))
    "Types with an associative binary operation and identity defined."
    (mempty (:a)))

  (define-class (Functor :f)
    "Types which can map an inner type where the mapping adheres to the identity and composition laws."
    (map ((:a -> :b) -> (:f :a) -> (:f :b))))

  (define-class (Functor :f => (Applicative :f))
    "Types which are a functor which can embed pure expressions and sequence operations."
    (pure (:a -> (:f :a)))
    (liftA2 ((:a -> :b -> :c) -> (:f :a) -> (:f :b) -> (:f :c))))

  (define-class (Applicative :m => (Monad :m))
    "Types which are monads as defined in Haskell. See https://wiki.haskell.org/Monad for more information."
    (>>= ((:m :a) -> (:a -> (:m :b)) -> (:m :b))))

  (declare >> (Monad :m => (:m :a) -> (:m :b) -> (:m :b)))
  (define (>> a b)
    (>>= a (fn (_) b)))

  (define-class (Monad :m => (MonadFail :m))
    (fail (String -> (:m :a))))

  (define-class (Applicative :f => (Alternative :f))
    "Types which are monoids on applicative functors."
    (alt ((:f :a) -> (:f :a) -> (:f :a)))
    (empty (:f :a)))

  (define-class (Foldable :container)
    "Types which can be folded into a single element.

`fold` is a left tail recursive fold

`foldr` is a right non tail recursive fold"
    (fold ((:accum -> :elt -> :accum) -> :accum -> :container :elt -> :accum))
    (foldr ((:elt -> :accum -> :accum) -> :accum -> :container :elt -> :accum)))

  (declare mconcat ((Foldable :f) (Monoid :a) => (:f :a) -> :a))
  (define  mconcat (fold <> mempty))

  (define-class (Traversable :t)
    (traverse (Applicative :f => (:a -> :f :b) -> :t :a -> :f (:t :b))))

  (declare sequence ((Traversable :t) (Applicative :f) => :t (:f :b) -> :f (:t :b)))
  (define sequence (traverse (fn (x) x)))

  ;;
  ;; Conversions
  ;;

  (define-class (Into :a :b)
    "INTO imples *every* element of :a can be represented by an element of :b. This conversion might not be injective (i.e., there may be elements in :a that don't correspond to any in :b)."
    (into (:a -> :b)))

  (define-class ((Into :a :b) (Into :b :a) => (Iso :a :b))
    "Opting into this marker typeclass imples that the instances for (Into :a :b) and (Into :b :a) form a bijection.")

  (define-instance (Into :a :a)
    (define (into x) x))

  (define-class (TryInto :a :b)
    "TRY-INTO implies *most* elements of :a can be represented exactly by an element of :b, but sometimes not. If not, an error string is returned."
    ;; Ideally we'd have an associated-type here instead of locking in
    ;; on String.
    (tryInto (:a -> (Result String :b))))

  (define-instance (Iso :a :a))

  ;;
  ;; Unwrappable for fallible unboxing
  ;;

  (declare error (String -> :a))
  (define (error str)
    "Signal an error by calling `CL:ERROR`."
    (lisp :a (str) (cl:error str)))

  (define-class (Unwrappable :container)
    "Containers which can be unwrapped to get access to their contents.

(unwrap-or-else SUCCEED FAIL CONTAINER) should invoke the SUCCEED continuation on the unwrapped contents of
CONTAINER when successful, or invoke the FAIL continuation with no arguments (i.e. with Unit as an argument)
when unable to unwrap a value.

The SUCCEED continuation will often, but not always, be the identity function. `as-optional` passes Some to
construct an Optional.

Typical `fail` continuations are:
- Return a default value, or
- Signal an error."
    (unwrap-or-else ((:elt -> :result)
                     -> (Unit -> :result)
                     -> (:container :elt)
                     -> :result)))

  (declare expect ((Unwrappable :container) =>
                   String
                   -> (:container :element)
                   -> :element))
  (define (expect reason container)
    "Unwrap CONTAINER, signaling an error with the description REASON on failure."
    (unwrap-or-else (fn (elt) elt)
                    (fn () (error reason))
                    container))

  (declare unwrap ((Unwrappable :container) =>
                   (:container :element)
                   -> :element))
  (define (unwrap container)
    "Unwrap CONTAINER, signaling an error on failure."
    (unwrap-or-else (fn (elt) elt)
                    (fn () (error (lisp String (container)
                                    (cl:format cl:nil "Unexpected ~a in UNWRAP"
                                               container))))
                    container))

  (declare with-default ((Unwrappable :container) =>
                         :element
                         -> (:container :element)
                         -> :element))
  (define (with-default default container)
    "Unwrap CONTAINER, returning DEFAULT on failure."
    (unwrap-or-else (fn (elt) elt)
                    (fn () default)
                    container))

  (declare as-optional ((Unwrappable :container) => (:container :elt) -> (Optional :elt)))
  (define (as-optional container)
    "Convert any Unwrappable container into an Optional, constructing Some on a successful unwrap and None on a failed unwrap."
    (unwrap-or-else Some
                    (fn () None)
                    container))

  ;;
  ;; hashing
  ;;

  (define-class (Eq :a => (Hash :a))
    "Types which can be hashed for storage in hash tables.

Invariant (== left right) implies (== (hash left) (hash right))."
    (hash (:a -> UFix)))

  (declare combine-hashes (UFix -> UFix -> UFix))
  (define (combine-hashes left right)
    (lisp UFix (left right)
      (#+sbcl sb-int:mix
       #-sbcl cl:logxor left right))))

(cl:defmacro define-sxhash-hasher (type)
  `(coalton-toplevel
     (define-instance (Hash ,type)
       (define (hash item)
         (lisp UFix (item)
           (cl:sxhash item))))))

#+sb-package-locks
(sb-ext:lock-package "COALTON-LIBRARY/CLASSES")
