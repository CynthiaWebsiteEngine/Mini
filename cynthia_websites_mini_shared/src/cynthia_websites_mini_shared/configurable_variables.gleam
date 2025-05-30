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
////
//// Please note: variables in the model are stored under the 'other' type, which means you'll have to decode their values
//// once more after transfer. However, by setting types beforehand you'll be able to directly decode them, instead of first having to decode them to a
//// `List(String)` and then manually having to convert their type.

/// Variable names and their pre-defined types.
pub const typecontrolled = [
  #("examplevar", var_string),
  #(
    // Template for the ownit layout
    "ownit_template",
    var_string,
  ),
]

/// An unsupported type, this is for example the type of any array or sub-table, as those aren't supported.
pub const var_unsupported = "unsupported"

/// Now, obviously this isn't a type supported directly in TOML.
///
/// This can still be created by using a `{ path = "filename.bin" }` or the `url` equevalent.
/// Note that bitstrings and strings are interchangeable, if you define a bitstring in typecontrolled, you'll get a
/// base64 delivered in your layout, wether it's source was a string or file.
/// If you decide you want a string, bitstrings will be converted for you.
/// If any of those conversions fail, client will be able to quit quickly, allowing author's to see the error.
pub const var_bitstring = "bits"

/// A string, also see bitstring to read how this is interchangeable.
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

/// A floating point number. Will be converted to int on the fly if needed.
pub const var_float = "float"

/// An integer number. Will be converted to float on the fly if needed.
pub const var_int = "integer"
