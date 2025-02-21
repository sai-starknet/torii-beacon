pub use dojo::world::Resource as DojoResource;

#[derive(Drop, starknet::Store, Serde, Default, Debug)]
pub enum Resource {
    #[default]
    Unregistered,
    Model,
    Event,
    Contract,
    Namespace,
    World,
    Library,
}


pub impl DojoResourceIntoResource of Into<DojoResource, Resource> {
    fn into(self: DojoResource) -> Resource {
        match self {
            DojoResource::Model => Resource::Model,
            DojoResource::Event => Resource::Event,
            DojoResource::Contract => Resource::Contract,
            DojoResource::Namespace => Resource::Namespace,
            DojoResource::World => Resource::World,
            DojoResource::Library => Resource::Library,
            DojoResource::Unregistered => Resource::Unregistered,
        }
    }
}
// #[derive(Drop, starknet::Store, Serde, Default, Debug)]
// pub enum Resource {
//     Model: (ContractAddress, felt252),
//     Event: (ContractAddress, felt252),
//     Contract: (ContractAddress, felt252),
//     Namespace: ByteArray,
//     World,
//     #[default]
//     Unregistered,
//     Library: (ClassHash, felt252),
// }


