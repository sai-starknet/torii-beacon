pub mod owners;
pub use owners::owners_component;

pub mod writers;
pub use writers::writers_component;


pub mod model;


pub mod errors;

pub mod interfaces {
    pub use super::beacon::{IBeaconDispatcher, IBeaconDispatcherTrait};
    pub use super::owners::{IBeaconOwnersDispatcher, IBeaconOwnersDispatcherTrait};
    pub use super::writers::{IBeaconWritersDispatcher, IBeaconWritersDispatcherTrait};
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
    pub mod component;
    pub mod registry;
    pub use registry::Registry;
    pub use component::emitter_component;
    pub use emitter_component::{
        DojoEventEmitter, HasComponent as HasEmitterComponent, ComponentState as EmitterState,
    };
}

pub mod dojo {
    pub mod schema;
    pub mod const_ns;
    pub mod const_ns_model;
    pub mod state_ns;
    pub mod arg_ns;
    pub mod traits;
    pub use const_ns::ConstNsBeaconEmitter;
    pub use state_ns::StateNsBeaconEmitter;
    pub use arg_ns::ArgNsBeaconEmitter;
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
