

#[starknet::contract]
pub mod m_$model_type$ {
    use super::$model_type$;

    #[storage]
    struct Storage {}

    #[derive(Drop, starknet::Event)]
    struct Model{
        model: $model_type$,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Model: Model,
    }

    #[abi(embed_v0)]
    impl $model_type$ModelImpl = beacon_entity::interface::ISaiModelImpl<ContractState, $model_type$>;
}