require "./prelude/atomic.cr"
require "./prelude/primitives.cr"

# order matters
require "./crystal_core/object"
require "./crystal_core/pointer"
require "./crystal_core/intrinsics"
require "./crystal_core/panic"
require "./crystal_core/slice"
require "./crystal_core/int"

# order not important
require "./crystal_core/char"
require "./crystal_core/proc"
require "./crystal_core/enum"
require "./crystal_core/bool"
require "./crystal_core/tuple"
require "./crystal_core/range"
require "./crystal_core/string"
require "./crystal_core/reference"
require "./crystal_core/static_array"
