pub mod owners;
pub use owners::owners_component;

pub mod writers;
pub use writers::writers_component;

pub mod resource {
    pub mod model;
    pub mod component;
    pub mod resource;
    pub use component::resource_component;
    pub use resource::{DojoResource, Resource};
}
pub use resource::resource_component;
pub use resource_component::HasComponent as ResourceComponent;

pub mod errors;

pub mod interfaces {
    pub use super::beacon::{IBeaconDispatcher, IBeaconDispatcherTrait};
    pub use super::owners::{IBeaconOwnersDispatcher, IBeaconOwnersDispatcherTrait};
    pub use super::writers::{IBeaconWritersDispatcher, IBeaconWritersDispatcherTrait};
    pub use super::resource::component::{IBeaconResourceDispatcher, IBeaconResourceDispatcherTrait};
}

pub mod beacon {
    pub mod components;
    pub mod interface;
    pub mod contract;
    pub mod dojo;
    pub use components::{IdValues, IdValuesArray, IdKeysValues};
    pub use interface::{IBeacon, IBeaconDispatcher, IBeaconDispatcherTrait};
}

pub mod emitter {
    pub mod traits;
    pub mod implementation;
}

pub mod dojo {
    pub mod schema;
}

pub mod utils {
    pub mod serde;
    pub mod poseidon;
    pub mod pedersen;
    pub mod starknet;
    pub use serde::{deserialize_unwrap, serialize_inline};
    pub use poseidon::poseidon_hash_value;
    pub use pedersen::{pedersen_array_hash, pedersen_fixed_array_hash};
    pub use starknet::{calculate_contract_address, calculate_udc_contract_address};
}

pub mod micro_world;
pub use micro_world::MicroEmitter;

#[cfg(test)]
mod tests {
    mod starknet;
}
