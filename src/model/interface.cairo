use dojo::meta::introspect::Struct;
use dojo::meta::layout::compute_packed_size;
use dojo::meta::{Introspect, Layout, Ty};

#[starknet::interface]
trait ISaiModel<TContractState> {
    fn schema(self: @TContractState) -> Struct;
    fn layout(self: @TContractState) -> Layout;
    fn unpacked_size(self: @TContractState) -> Option<usize>;
    fn packed_size(self: @TContractState) -> Option<usize>;
}


#[starknet::embeddable]
impl ISaiModelImpl<TContractState, M, +Introspect<M>> of ISaiModel<TContractState> {
    fn schema(self: @TContractState) -> Struct {
        match Introspect::<M>::ty() {
            Ty::Struct(s) => s,
            _ => panic!("Expected a struct type"),
        }
    }

    fn layout(self: @TContractState) -> Layout {
        Introspect::<M>::layout()
    }

    fn unpacked_size(self: @TContractState) -> Option<usize> {
        Introspect::<M>::size()
    }

    fn packed_size(self: @TContractState) -> Option<usize> {
        compute_packed_size(Introspect::<M>::layout())
    }
}
