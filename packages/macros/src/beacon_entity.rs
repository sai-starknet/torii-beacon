use crate::utils::str_to_token_stream;
use cairo_lang_defs::patcher::RewriteNode;
use cairo_lang_macro::{attribute_macro, ProcMacroResult, TokenStream};
use cairo_lang_reader::generic_param::OptionWrappedGenericParamList;
use cairo_lang_reader::item::Struct;
use cairo_lang_reader::{
    parse_token_stream_to_syntax_file, Item, QueryAttrs, SyntaxElementTrait, Visibility,
};
use cairo_lang_utils::unordered_hash_map::UnorderedHashMap;
use convert_case::{Case, Casing};

const DERIVE_ATTR: &str = "derive";
const BEACON_ENTITY_CODE_PATCH: &str = include_str!("./beacon_entity.patch.cairo");

#[attribute_macro]
pub fn beacon_entity(_attr: TokenStream, original: TokenStream) -> ProcMacroResult {
    let (file, _) = parse_token_stream_to_syntax_file(original);
    let mut diagnostics = vec![];
    let cairo_struct = match file.item() {
        Item::Struct(item) => item,
        _ => {
            diagnostics.push("Expected a struct".to_string());
            return ProcMacroResult::new(str_to_token_stream(""));
        }
    };
    let name = cairo_struct.name();
    let node: RewriteNode = RewriteNode::interpolate_patched(
        BEACON_ENTITY_CODE_PATCH,
        &UnorderedHashMap::from([
            ("model_type".to_string(), RewriteNode::Text(name.clone())),
            (
                "model_name".to_string(),
                RewriteNode::Text(name.to_case(Case::Snake)),
            ),
        ]),
    );
    let mut builder = file.patch_builder();

    builder.add_modified(RewriteNode::Text(remove_struct_derive(cairo_struct)));
    builder.add_modified(node);

    let (code, _) = builder.build();
    ProcMacroResult::new(str_to_token_stream(&code))
}

fn remove_struct_derive(node: Struct) -> String {
    let attributes: Vec<String> = node
        .query_attr(DERIVE_ATTR)
        .flat_map(move |attr| {
            attr.arguments()
                .map(|arg| arg.get_text().trim().to_string())
        })
        .filter(|arg| match arg.as_str() {
            "Copy" | "Drop" | "Clone" | "Debug" | "Default" | "Destruct" | "Hash"
            | "PanicDestruct" | "PartialEq" | "Serde" => false,
            _ => true,
        })
        .collect();
    let derive = if attributes.is_empty() {
        String::new()
    } else {
        format!("#[{}({})]\n", DERIVE_ATTR, attributes.join(", "))
    };
    let visibility = match node.visibility() {
        Visibility::Pub => "pub ",
        Visibility::Default => "",
    };
    let name = node.name();
    let params: String = node
        .generic_params::<OptionWrappedGenericParamList>()
        .get_text();
    let members = node
        .get_child_syntax_element::<{ Struct::INDEX_MEMBERS }>()
        .get_text();
    format!(
        r#"{derive}{visibility}struct {name}{params} {{
{members}
}}
"#
    )
}
