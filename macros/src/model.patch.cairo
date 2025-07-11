#[starknet::contract]
mod m_$model_name$ {
    use super::$model_type$;

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl $model_type$DojoDeployedModelImpl = dojo::model::component::IDeployedModelImpl<ContractState, $model_type$>;

    #[abi(embed_v0)]
    impl $model_type$DojoStoredModelImpl = dojo::model::component::IStoredModelImpl<ContractState, $model_type$>;

    #[abi(embed_v0)]
    impl $model_type$DojoModelImpl = dojo::model::component::IModelImpl<ContractState, $model_type$>;
    
    #[constructor]
    fn constructor(ref self: ContractState, model: $model_type$) -> $model_type$ {
        model
    }
}