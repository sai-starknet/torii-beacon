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

pub mod errors;
pub mod starknet;

pub mod interfaces {
    pub use super::beacon::{IBeaconDispatcher, IBeaconDispatcherTrait};
    pub use super::owners::{IBeaconOwnersDispatcher, IBeaconOwnersDispatcherTrait};
    pub use super::writers::{IBeaconWritersDispatcher, IBeaconWritersDispatcherTrait};
    pub use super::resource::component::{IBeaconResourceDispatcher, IBeaconResourceDispatcherTrait};
}
pub mod beacon;

pub mod models;

#[cfg(test)]
mod tests {
    mod utils;
}
