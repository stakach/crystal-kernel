require "./prelude/atomic"
require "./prelude/primitives"

# order matters
require "./prelude/crystal_core/object"
require "./prelude/crystal_core/pointer"
require "intrinsics"
require "comparable"
require "./prelude/crystal_core/panic"
require "./prelude/crystal_core/slice"
require "./prelude/crystal_core/int"

# order not important
require "annotations"
require "nil"
require "./prelude/crystal_core/char"
require "./prelude/crystal_core/proc"
require "./prelude/crystal_core/enum"
require "./prelude/crystal_core/bool"
require "./prelude/crystal_core/tuple"
require "./prelude/crystal_core/range"
require "./prelude/crystal_core/string"
require "./prelude/crystal_core/reference"
require "./prelude/crystal_core/static_array"
