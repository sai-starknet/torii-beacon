use cairo_lang_defs::patcher::RewriteNode;
use cairo_lang_macro::{attribute_macro, ProcMacroResult, TokenStream};
use cairo_lang_reader::generic_param::OptionWrappedGenericParamList;
use cairo_lang_reader::item::Struct;
use cairo_lang_reader::{parse_token_stream_to_syntax_file, Item, SyntaxElementTrait, Visibility};
use cairo_lang_utils::unordered_hash_map::UnorderedHashMap;
use convert_case::{Case, Casing};

pub const MODEL_ATTRIBUTE_MACRO: &str = "Model";
const MODEL_CODE_PATCH: &str = include_str!("./model.patch.cairo");

#[attribute_macro]
pub fn beacon_model(_attr: TokenStream, original: TokenStream) -> ProcMacroResult {
    let (file, _) = parse_token_stream_to_syntax_file(original);
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
    
    builder.add_modified(RewriteNode::Text(remove_struct_derive(cairo_struct)));
    builder.add_modified(node);

    let (code, _) = builder.build();
    ProcMacroResult::new(TokenStream::new(code.to_string()))
}

fn remove_struct_derive(node: Struct) -> String{
    let visibility = match node.visibility(){
        Visibility::Pub => "pub ",
        Visibility::Default => "",
    };
    let name = node.name();
    let params: String = node.generic_params::<OptionWrappedGenericParamList>().get_text();
    let members = node.get_child_syntax_element::<{Struct::INDEX_MEMBERS}>().get_text();
    // members.text()
    // let params = if  {
    //     format!("<{}>", params)
    // } else {
    //     "".to_string()
    // };
    format!(
r#"{visibility}struct {name}{params} {{
{members}
}}
"#
    )
}