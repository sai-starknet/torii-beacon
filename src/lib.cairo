pub mod errors;


pub mod model {
    pub mod interface;
}

pub mod emitter {
    pub mod component;
    pub mod const_entity;
    pub mod entity;
    pub mod syscalls;
    pub use component::{ToriiRegistryEmitter, emitter_component};
    pub use emitter_component::{
        ComponentState as EmitterState, Event as EmitterEvents, HasComponent as HasEmitterComponent,
        ToriiEventEmitter,
    };
    pub use entity::EntityEmitter;
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
    pub mod state_ns;
    pub mod traits;
    pub use arg_ns::ArgNsBeaconEmitter;
    pub mod model;
    pub mod registry;
    pub use registry::DojoRegistry;
    pub use state_ns::StateNsBeaconEmitter;
}

pub mod utils {
    pub mod pedersen;
    pub mod starknet;
    pub use pedersen::{pedersen_array_hash, pedersen_fixed_array_hash};
    pub use starknet::{
        calculate_contract_address, calculate_udc_contract_address, calculate_utc_zero_address,
    };
}

pub mod schema;
pub mod external {
    pub use sai_core_utils::SerdeAll;
}


#[cfg(test)]
mod tests {
    mod starknet;
}
