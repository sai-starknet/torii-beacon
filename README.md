# dojo-beacon

The dojo beacon is a lightweight component that can be added to a starknet contract to provide a simple way to emit events that can be indexed by torii.

This allows for contracts to define their own storage and permissions but still benefit from easy off-chain indexing.

A simple example could look like this:

```rust

#[dojo::model]
#[derive(Drop, Serde)]
struct MyModel {
    #[key]
    pub id: felt252,
    pub value: u32,
}

#[starknet::contract]
mod my_contract {
    use dojo_beacon::dojo::const_ns;
    use dojo_beacon::emitter::Registry;
    use dojo_beacon::{EmitterEvents, emitter_component};
    use super::MyModel;

    const NAMESPACE_HASH: felt252 = bytearray_hash!("my_namespace");

    component!(path: emitter_component, storage: emitter, event: EmitterEvents);
    impl Beacon = const_ns::ConstNsBeaconEmitter<NAMESPACE_HASH, ContractState>;

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
    ) {
        self.register_model("my_namespace", model_class_hash);

        self.emit_model(@MyModel { id: 1, value: 42 });
        self.emit_member::<MyModel>(selector!("value"), 1, 100);
    }

}
```
