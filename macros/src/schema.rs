use crate::aux_data::Member;
use cairo_lang_defs::patcher::{PatchBuilder, RewriteNode};
use cairo_lang_macro::{derive_macro, ProcMacroResult, TokenStream};
use cairo_lang_parser::utils::SimpleParserDatabase;
use cairo_lang_syntax::node::ast::Attribute;
use cairo_lang_syntax::node::ast::{
    Expr, ItemEnum, ItemStruct, Member as MemberAst, OptionTypeClause, TypeClause, Variant,
};
use cairo_lang_syntax::node::db::SyntaxGroup;
use cairo_lang_syntax::node::kind::SyntaxKind::{TerminalStruct, TokenIdentifier};
use cairo_lang_syntax::node::{Terminal, TypedStablePtr, TypedSyntaxNode};

pub const SCHEMA_DERIVE_MACRO: &str = "Schema";

#[derive_macro]
pub fn schema_macro(token_stream: TokenStream) -> ProcMacroResult {}

pub fn build_schema_generated(
    db: &dyn SyntaxGroup,
    struct_name: &String,
    members: Vec<&Member>,
) -> String {
    let mut members;
    let mut serialize_member_to_array: Vec<RewriteNode> = vec![];
}

pub fn parse_members(db: &dyn SyntaxGroup, members: &[MemberAst]) -> Vec<Member> {
    members
        .iter()
        .map(|member_ast| Member {
            name: member_ast.name(db).text(db).to_string(),
            ty: member_ast
                .type_clause(db)
                .ty(db)
                .as_syntax_node()
                .get_text(db)
                .trim()
                .to_string(),
            key: is_key,
        })
        .collect::<Vec<_>>()
}

pub fn serialize_member_to_array(array_name: String, member: &Member) -> RewriteNode {
    RewriteNode::Text(format!(
        "{}.append(dojo::utils::serialize_inline(@self.{}));\n",
        array_name, member.name
    ))
}
