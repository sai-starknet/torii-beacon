#[derive(Drop, Serde, Introspect)]
#[beacon_entity]
struct MyTable {
    pub value_1: u8,
    pub value_2: felt252,
    pub value_3: u128,
    pub value_4: u256,
}

#[derive(Drop, Serde, Schema)]
struct MySchema {
    pub value_1: u8,
    pub value_4: u256,
}

// define the interface
#[starknet::interface]
trait IActions<T> {
    fn set_entity(ref self: T);
    fn update_entity(ref self: T);
}

#[starknet::contract]
pub mod example {
    use beacon_library::torii::{register_table, register_table_with_schema};
    use beacon_library::{ToriiTable, set_entity, set_member, set_schema};
    use starknet::ClassHash;
    use super::{IActions, MySchema, MyTable};
    const TABLE_1_ID: felt252 = bytearrays_hash!("my_ns", "my_table_1");
    const TABLE_2_ID: felt252 = bytearrays_hash!("my_other_ns", "my_table_2");

    impl Table = ToriiTable<TABLE_1_ID>;

    #[storage]
    struct Storage {}

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    #[constructor]
    fn constructor(ref self: ContractState, class_hash: ClassHash) {
        register_table("my_other_ns", "my_table_2", class_hash);
        register_table_with_schema::<MyTable>("my_ns", "my_table_1");
        Table::set_entity(1, @MyTable { value_1: 42, value_2: 1, value_3: 2, value_4: 3 });
        set_entity(TABLE_2_ID, 1, @MyTable { value_1: 42, value_2: 1, value_3: 2, value_4: 5 });
    }

    #[abi(embed_v0)]
    impl IActionsImpl of IActions<ContractState> {
        fn set_entity(ref self: ContractState) {
            let my_table_1 = MyTable { value_1: 42, value_2: 100, value_3: 200, value_4: 300 };
            let my_table_2 = MyTable { value_1: 42, value_2: 100, value_3: 200, value_4: 300 };
            Table::set_entity(12, @my_table_1);
            set_entity(TABLE_2_ID, 42, @my_table_2);
            set_member(TABLE_1_ID, selector!("value_1"), 12, 100);
        }

        fn update_entity(ref self: ContractState) {
            let schema = MySchema { value_1: 10, value_4: 500 };
            Table::set_schema(12, @schema);
            set_schema(TABLE_2_ID, 42, @schema);
        }
    }
}
