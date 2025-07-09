// #[derive(Drop, Serde)]
// struct TestStruct<T> {
//     name: felt252,
//     number: Span<T>,
// }

// #[derive(Drop, PrintAll)]
// // com1
// struct Test2Struct<T> {
//     // com2
//     name: felt252, // com3
//     number: (@Array<T>, felt252, (TestStruct<T>, Span<T>)),
// }

#[derive(Drop, PrintAll)]
struct Test3Struct<const N: usize> {
    fixed: [bool; N],
}
// #[derive(Drop, PrintTree, PrintItem)]
// enum Something {
//     #[default]
//     Var,
//     Var2: (bool,),
// }
// mod somethingelse {
//     #[event]
//     #[derive(Drop, PrintTree)]
//     pub struct TestModel<T, S> {
//         #[key]
//         name: ByteArray,
//         number: u256,
//         test: TestStruct,
//         pub tuple: (felt252, Array<felt252>, ()),
//         none: (),
//         something: core::felt252,
//         array: Array<Test2Struct<(T, S, felt252)>>,
//     }
// }


