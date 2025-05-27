//// Configurable variables module
////
//// This module doesn't exist to hold any actual types for configurable variables, 
//// as that is implemented in `cynthia_websites_mini_shared/configtype`. Also not 
//// Providing any fucntions for reading, serialising etc. those functions are implemented
//// in their relative `cynthia_websites_mini_server` and `cynthia_websites_mini_client` modules.
//// 
//// However, these variables are dynamically marked and not typestrongly shipped to the client-side.
//// This compromises the guarantee of Gleams type safety mechanisms, and might create errors on users'
//// ends without any valid way of reproducing. This also makes it very hard to do certain optimisations
//// 
//// Luckily, those dynamic markers are developed by yours truly, and of course I keep type information with them.
//// Even though some values might still be arbitrarily typed and left unchecked, types you add to the below
//// const typecontrolled variable, WILL be checked in runtime.

pub const typecontrolled = [#("examplevar", var_string)]

/// An unsupported type, this is for example the type of any array or sub-table, as those aren't supported.
pub const var_unsupported = "unsupported"

/// A string
pub const var_string = "string"

/// A boolean
pub const var_boolean = "boolean"

/// A date with no time attached
pub const var_date = "date"

/// A date and a time, warning: 
/// Using an offset that implies anything else than 'local', will
/// change the type to unsupported.
/// Use an int containing a unix timestamp over this.
pub const var_datetime = "datetime"

/// A time, consisting of hour, minute, second and millisecond.
pub const var_time = "time"

/// A floating point number.
pub const var_float = "float"

/// An integer number.
pub const var_int = "integer"
