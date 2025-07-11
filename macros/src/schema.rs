use cairo_lang_defs::patcher::RewriteNode;
use cairo_lang_macro::{derive_macro, ProcMacroResult, TokenStream};
use cairo_lang_reader::{parse_token_stream_to_syntax_file, Item, SyntaxElementTrait};
use cairo_lang_utils::unordered_hash_map::UnorderedHashMap;
use starknet::core::utils::get_selector_from_name;
pub const SCHEMA_DERIVE_MACRO: &str = "Schema";
const SCHEMA_CODE_PATCH: &str = include_str!("./schema.patch.cairo");

#[derive_macro]
pub fn schema(token_stream: TokenStream) -> ProcMacroResult {
    let (file, _) = parse_token_stream_to_syntax_file(token_stream);
    let mut diagnostics = vec![];
    let cairo_struct = match file.item() {
        Item::Struct(item) => item,
        _ => {
            diagnostics.push("Expected a struct".to_string());
            return ProcMacroResult::new(TokenStream::new("".to_string()));
        }
    };
    let mut serialize_members_to_array: Vec<RewriteNode> = vec![];
    let mut member_selctors = vec![];
    for member in cairo_struct.members() {
        let member_name = member.name();
        member_selctors.push(RewriteNode::Text(format!(
            "\t    {},\n",
            get_selector_from_name(&member_name)
                .expect("invalid member name")
                .to_string()
        )));
        serialize_members_to_array.push(serialize_member_to_array(
            "serialized_array".to_string(),
            &member_name,
        ));
    }

    let node: RewriteNode = RewriteNode::interpolate_patched(
        SCHEMA_CODE_PATCH,
        &UnorderedHashMap::from([
            (
                "struct_type".to_string(),
                RewriteNode::Text(cairo_struct.name()),
            ),
            (
                "serialize_members_to_array".to_string(),
                RewriteNode::new_modified(serialize_members_to_array),
            ),
            (
                "member_selectors".to_string(),
                RewriteNode::new_modified(member_selctors),
            ),
        ]),
    );
    let mut builder = file.patch_builder();

    builder.add_modified(node);

    let (code, _) = builder.build();
    ProcMacroResult::new(TokenStream::new(code.to_string()))
}

pub fn serialize_member_to_array(array_name: String, member_name: &String) -> RewriteNode {
    RewriteNode::Text(format!(
        "\t{}.append(dojo_beacon::utils::serialize_inline(self.{}).span());\n",
        array_name, member_name
    ))
}
