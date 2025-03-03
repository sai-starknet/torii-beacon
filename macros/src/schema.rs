use crate::{CairoNameType, CairoTypeParser};
use cairo_lang_defs::patcher::{PatchBuilder, RewriteNode};
use cairo_lang_macro::{derive_macro, ProcMacroResult, TokenStream};
use cairo_lang_parser::utils::SimpleParserDatabase;
use cairo_lang_utils::unordered_hash_map::UnorderedHashMap;
use dojo_lang::derive_macros::print;
use starknet::core::utils::get_selector_from_name;

pub const SCHEMA_DERIVE_MACRO: &str = "Schema";
const SCHEMA_CODE_PATCH: &str = include_str!("./schema.patch.cairo");

// fn parse_member(
//     db: &dyn SyntaxGroup,
//     parsed: &SyntaxNode,
//     diagnostics: &mut Vec<PluginDiagnostic>,
// ) -> Option<(Member, String, Vec<String>, Vec<NameType>)> {
//     println!("-----------------------------------");
//     for n in parsed.descendants(db) {
//         match n.kind(db) {
//             SyntaxKind::Member => {
//                 let struct_ast = ast::Member::from_syntax_node(db, n);
//                 let struct_type = struct_ast
//                     .name(db)
//                     .as_syntax_node()
//                     .get_text(db)
//                     .trim()
//                     .to_string();
//                 let members = struct_ast
//                     .members(db)
//                     .elements(db)
//                     .iter()
//                     .map(|m| {
//                         println!("{:?}", m.as_syntax_node());
//                         let (struct_ast, struct_type, attrs, members) =
//                             parse_struct(db, &m.as_syntax_node(), diagnostics).unwrap();
//                         println!("{:?}", members);
//                         NameType {
//                             name: m.name(db).text(db).to_string(),
//                             ty: m
//                                 .type_clause(db)
//                                 .ty(db)
//                                 .as_syntax_node()
//                                 .get_text(db)
//                                 .trim()
//                                 .to_string(),
//                         }
//                     })
//                     .collect::<Vec<_>>();
//                 let attrs = extract_derive_attr_names(
//                     db,
//                     diagnostics,
//                     struct_ast.attributes(db).query_attr(db, "derive"),
//                 );

//                 return Some((struct_ast, struct_type, attrs, members));
//             }
//             _ => {
//                 continue;
//             }
//         };
//     }
//     None
// }

impl CairoTypeParser for SimpleParserDatabase {}

#[derive_macro]
pub fn schema(token_stream: TokenStream) -> ProcMacroResult {
    let db = SimpleParserDatabase::default();
    let (parsed, _diag) = db.parse_virtual_with_diagnostics(token_stream);
    let mut diagnostics = vec![];
    let parsed_struct = db.parse_struct(&parsed, &mut diagnostics).unwrap();
    println!("{:?}", parsed_struct);
    let mut serialize_members_to_array: Vec<RewriteNode> = vec![];
    let mut member_selctors = vec![];
    for member in parsed_struct.members {
        member_selctors.push(RewriteNode::Text(format!(
            "\t    {},\n",
            get_selector_from_name(&member.name)
                .expect("invalid member name")
                .to_string()
        )));
        serialize_members_to_array.push(serialize_member_to_array(
            "serialized_array".to_string(),
            &member,
        ));
    }

    let node: RewriteNode = RewriteNode::interpolate_patched(
        SCHEMA_CODE_PATCH,
        &UnorderedHashMap::from([
            (
                "struct_type".to_string(),
                RewriteNode::Text(parsed_struct.name),
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
    let mut builder = PatchBuilder::new(&db, &parsed_struct.ast);
    builder.add_modified(node);

    let (code, code_mappings) = builder.build();
    println!("{}", code);
    ProcMacroResult::new(TokenStream::new("".to_string()))
}

pub fn serialize_member_to_array(array_name: String, member: &CairoNameType) -> RewriteNode {
    RewriteNode::Text(format!(
        "\t{}.append(dojo_beacon::utils::serialize_inline(self.{}).span());\n",
        array_name, member.name
    ))
}
