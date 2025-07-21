// #[sai::model]
// #[derive(Drop, Serde, Introspect)]
// struct MyTable {
//     pub value_1: u8,
//     pub value_2: felt252,
//     pub value_3: i128,
//     pub value_4: u256,
// }

// #[derive(Drop, Serde, Schema)]
// struct MySchema {
//     pub value_1: u8,
//     pub value_4: u256,
// }

// define the interface
#[starknet::interface]
trait IActions<T> {
    fn set_entity(ref self: T);
    fn update_entity(ref self: T, entity: felt252);
}

#[starknet::contract]
pub mod actions {
    use starknet::ClassHash;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use super::{MySchema, MyTable};
    use torii_beacon::emitter::const_entity;
    use torii_beacon::{EmitterEvents, emitter_component};
    const NAMESPACE_HASH: felt252 = bytearray_hash!("my_ns");
    const TABLE_ID: felt252 = selector_from_tag!("my_ns-my_table");


    component!(path: emitter_component, storage: emitter, event: EmitterEvents);
    impl Beacon = const_entity::ConstEntityEmitter<TABLE_ID, ContractState>;
    // impl Events = resource_component::BeaconEventsImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        pub emitter: emitter_component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        EmitterEvents: EmitterEvents,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        model_class_hash: ClassHash,
        positions_class_hash: ClassHash,
        moved_class_hash: ClassHash,
    ) {
        self.emit_register_model("my_ns", "my_table", model_class_hash);
    }
}
