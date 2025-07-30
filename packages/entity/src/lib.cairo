pub mod interface;
pub use beacon_schema::SchemaGenerated;
use dojo::meta::{Introspect, Ty};
pub use sai_core_utils::SerdeAll;

pub fn get_schema_size<T, +Introspect<T>>() -> u32 {
    match Introspect::<T>::ty() {
        Ty::Struct(fields) => fields.serialize_all().len(),
        _ => panic!("Expected a struct type"),
    }
}

