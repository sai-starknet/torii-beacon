use cairo_lang_macro::{derive_macro, ProcMacroResult, TokenStream};
use cairo_lang_parser::printer::print_tree;
use cairo_lang_parser::utils::SimpleParserDatabase;

#[derive_macro]
pub fn print_all(token_stream: TokenStream) -> ProcMacroResult {
    let db = SimpleParserDatabase::default();
    let (parsed, _diag) = db.parse_virtual_with_diagnostics(token_stream);
    println!("{}", print_tree(&db, &parsed, true, false));

    ProcMacroResult::new(TokenStream::new("".to_string()))
}

// #[derive_macro]
// pub fn print_item(token_stream: TokenStream) -> ProcMacroResult {
//     let (item, _) = derive_token_stream_to_type(token_stream);
//     println!("{}", print_tree(item.db(), &item.syntax_node(), true, true));
//     ProcMacroResult::new(TokenStream::new("".to_string()))
// }

// #[derive_macro]
// pub fn print_members(token_stream: TokenStream) -> ProcMacroResult {
//     let (item, _) = derive_token_stream_to_type(token_stream);
//     let cairo_struct = match item {
//         Item::Struct(item) => item,
//         _ => {
//             return ProcMacroResult::new(TokenStream::new("".to_string()));
//         }
//     };
//     for member in cairo_struct.members() {
//         let string = member.type_string();
//         println!("{}", string);
//     }
//     ProcMacroResult::new(TokenStream::new("".to_string()))
// }
