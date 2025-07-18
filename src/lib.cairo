pub mod errors;


pub mod model;
pub mod serialized_data;

pub mod emitter {
    pub mod component;
    pub mod registry;
    pub use component::emitter_component;
    pub use emitter_component::{
        ComponentState as EmitterState, DojoEventEmitter, Event as EmitterEvents,
        HasComponent as HasEmitterComponent,
    };
    pub use registry::Registry;
}
pub use emitter::{EmitterEvents, EmitterState, HasEmitterComponent, emitter_component};

pub mod registry {
    mod component;
    pub use component::registry_component;
    pub use registry_component::{
        ComponentState as RegistryState, HasComponent as HasRegistryComponent, RegistryTrait,
    };
}
pub use registry::registry_component;

pub mod dojo {
    pub mod arg_ns;
    pub mod const_ns;
    pub mod schema;
    pub mod state_ns;
    pub mod traits;
    pub use arg_ns::ArgNsBeaconEmitter;
    pub use schema::Schema;
    pub use state_ns::StateNsBeaconEmitter;
}

pub mod utils {
    pub mod pedersen;
    pub mod starknet;
    pub use pedersen::{pedersen_array_hash, pedersen_fixed_array_hash};
    pub use starknet::{calculate_contract_address, calculate_udc_contract_address};
}

#[cfg(test)]
mod tests {
    mod starknet;
}
