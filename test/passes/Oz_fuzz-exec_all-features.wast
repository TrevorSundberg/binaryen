(module
 (type $struct (struct i32))
 (type $superstruct (struct i32 f64))
 (type $bytes (array (mut i8)))
 (import "fuzzing-support" "log-i32" (func $log (param i32)))
 (func "structs"
  (local $x (ref null $struct))
  (local $y (ref null $struct))
  (local.set $x
   (struct.new_default_with_rtt $struct
    (rtt.canon $struct)
   )
  )
  ;; The value is initialized to 0
  ;; Note: -Oz will optimize all these to constants thanks to Precompute
  (call $log
   (struct.get $struct 0 (local.get $x))
  )
  ;; Assigning a value works
  (struct.set $struct 0
   (local.get $x)
   (i32.const 42)
  )
  (call $log
   (struct.get $struct 0 (local.get $x))
  )
  ;; References are references, so writing to one's value affects the other's
  (local.set $y (local.get $x))
  (struct.set $struct 0
   (local.get $y)
   (i32.const 100)
  )
  (call $log
   (struct.get $struct 0 (local.get $x))
  )
  (call $log
   (struct.get $struct 0 (local.get $y))
  )
 )
 (func "arrays"
  (local $x (ref null $bytes))
  (local.set $x
   (array.new_with_rtt $bytes
    (rtt.canon $bytes)
    (i32.const 50) ;; size
    (i32.const 42) ;; value to splat into the array
   )
  )
  ;; The length should be 50
  (call $log
   (array.len $bytes (local.get $x))
  )
  ;; The value should be 42
  (call $log
   (array.get_u $bytes (local.get $x) (i32.const 10))
  )
  ;; Write a value that will be truncated into an i8
  (array.set $bytes (local.get $x) (i32.const 10) (i32.const 0xff80))
  ;; The value should be 0x80 (-128 or 128 depending on signed/unsigned)
  (call $log
   (array.get_u $bytes (local.get $x) (i32.const 10))
  )
  (call $log
   (array.get_s $bytes (local.get $x) (i32.const 10))
  )
  ;; Other items than the one at index 10 are unaffected.
  (call $log
   (array.get_s $bytes (local.get $x) (i32.const 20))
  )
 )
 (func "rtts"
  (local $x (rtt $struct))
  (local $y (rtt $superstruct))
  (local $z (rtt $superstruct))
  (local $any anyref)
  (local.set $x (rtt.canon $struct))
  (local.set $y (rtt.sub $superstruct (local.get $x)))
  (local.set $z (rtt.canon $superstruct))
  ;; Casting null returns null.
  (call $log (ref.is_null
   (ref.cast $struct (ref.null $struct) (local.get $x))
  ))
  ;; Testing null returns 0.
  (call $log
   (ref.test $struct (ref.null $struct) (local.get $x))
  )
  ;; Testing something completely wrong (struct vs array) returns 0.
  (call $log
   (ref.test $struct
    (array.new_with_rtt $bytes
     (rtt.canon $bytes)
     (i32.const 10)
     (i32.const 20)
    )
    (local.get $x)
   )
  )
  ;; Testing a thing with the same RTT returns 1.
  (call $log
   (ref.test $struct
    (struct.new_default_with_rtt $struct
     (local.get $x)
    )
    (local.get $x)
   )
  )
  ;; A bad downcast returns 0: we create a struct, which is not a superstruct.
  (call $log
   (ref.test $superstruct
    (struct.new_default_with_rtt $struct
     (local.get $x)
    )
    (local.get $z)
   )
  )
  ;; Create a superstruct with RTT y, and upcast statically to anyref.
  (local.set $any
   (struct.new_default_with_rtt $superstruct
    (local.get $y)
   )
  )
  ;; Casting to y, the exact same RTT, works.
  (call $log
   (ref.test $superstruct
    (local.get $any)
    (local.get $y)
   )
  )
  ;; Casting to z, another RTT of the same data type, fails.
  (call $log
   (ref.test $superstruct
    (local.get $any)
    (local.get $z)
   )
  )
  ;; Casting to x, the parent of y, works.
  (call $log
   (ref.test $struct
    (local.get $any)
    (local.get $x)
   )
  )
 )
)
