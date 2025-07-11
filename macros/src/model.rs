use cairo_lang_defs::patcher::RewriteNode;
use cairo_lang_macro::{attribute_macro, ProcMacroResult, TokenStream};
use cairo_lang_reader::{parse_token_stream_to_syntax_file, Item, SyntaxElementTrait};
use cairo_lang_utils::unordered_hash_map::UnorderedHashMap;
use convert_case::{Case, Casing};
use starknet::core::utils::get_selector_from_name;

pub const MODEL_ATTRIBUTE_MACRO: &str = "Model";
const MODEL_CODE_PATCH: &str = include_str!("./model.patch.cairo");

#[attribute_macro]
pub fn model(attr: TokenStream, code: TokenStream) -> ProcMacroResult {
    let (file, _) = parse_token_stream_to_syntax_file(token_stream);
    let mut diagnostics = vec![];
    let cairo_struct = match file.item() {
        Item::Struct(item) => item,
        _ => {
            diagnostics.push("Expected a struct".to_string());
            return ProcMacroResult::new(TokenStream::new("".to_string()));
        }
    };
    let name = cairo_struct.name();
    let node: RewriteNode = RewriteNode::interpolate_patched(
        MODEL_CODE_PATCH,
        &UnorderedHashMap::from([
            ("model_type".to_string(), RewriteNode::Text(name.clone())),
            (
                "model_name".to_string(),
                RewriteNode::Text(name.to_case(Case::Snake)),
            ),
        ]),
    );
    let mut builder = file.patch_builder();

    builder.add_modified(node);

    // let (code, code_mappings) = builder.build();
    // println!("{}", code);
    ProcMacroResult::new(TokenStream::new("".to_string()))
}
