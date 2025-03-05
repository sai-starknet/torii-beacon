use cairo_lang_defs::plugin::PluginDiagnostic;
use cairo_lang_diagnostics::Severity;
use cairo_lang_parser::printer::print_tree;
use cairo_lang_syntax::attribute::structured::{AttributeArgVariant, AttributeStructurize};
use cairo_lang_syntax::node::ast::{Expr, ItemEnum, ItemStruct, OptionTypeClause};
use cairo_lang_syntax::node::db::SyntaxGroup;
use cairo_lang_syntax::node::helpers::QueryAttrs;
use cairo_lang_syntax::node::kind::SyntaxKind;
use cairo_lang_syntax::node::{ast, SyntaxNode, Terminal, TypedSyntaxNode};

#[derive(Clone)]
pub struct CairoStruct {
    pub derives: Vec<String>,
    pub visibility: Visibility,
    pub name: String,
    pub generic_params: Vec<String>,
    pub members: Vec<Member>,
    pub ast: ItemStruct,
}

struct Struct<'a> {
    db: &'a dyn SyntaxGroup,
    struct_ast: ItemStruct,
}

#[derive(Clone, Debug)]
pub struct CairoEnum {
    pub derives: Vec<String>,
    pub visibility: Visibility,
    pub name: String,
    pub generic_params: Vec<String>,
    pub variants: Vec<Variant>,
    pub default: Option<String>,
    pub ast: ItemEnum,
}

#[derive(Clone, Debug)]
pub struct Member {
    pub visibility: Visibility,
    pub name: String,
    pub ty: Ty,
    pub ast: ast::Member,
}

#[derive(Clone, Debug)]
pub struct Variant {
    pub name: String,
    pub ty: Option<Ty>,
    pub ast: ast::Variant,
}

#[derive(Clone, Debug)]
pub struct Attribute {
    name: String,
    args: ast::ArgList,
    ast: ast::Attribute,
}

#[derive(Clone, Debug)]
pub struct CairoTypePath {
    pub path: String,
    pub generic_args: Vec<Ty>,
}
#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub struct NamedType {
    pub name: String,
    pub ty: Ty,
}

#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub enum GenericParam {
    Type(String),
    Const(NamedType),
    ImplNamed(ImplNamed),
    ImplAnonymous(ast::GenericParamImplAnonymous),
    NegativeImpl(ast::GenericParamNegativeImpl),
}

#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub struct ImplNamed {
    pub name: String,
    pub trait_path: String,
    pub type_constraints: ast::OptionAssociatedItemConstraints,
}

#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub enum Ty {
    Path(String),
    Tuple(Vec<Ty>),
}

#[derive(Clone, Debug)]
enum Visibility {
    Default,
    Pub,
}

// impl ToString for CairoSubType {
//     fn to_string(&self) -> String {
//         match self {
//             CairoSubType::Path(path) => path.clone(),
//             CairoSubType::Tuple(types) => {
//                 let types = types.iter().map(|t| t.to_string()).collect::<Vec<_>>();
//                 format!("({})", types.join(", "))
//             }
//             CairoSubType::None => "()".to_string(),
//         }
//     }
// }

pub trait CairoTypeParser: SyntaxGroup + Sized {
    fn parse_item_struct_members(&self, struct_ast: &ItemStruct) -> Vec<Member> {
        struct_ast
            .members(self)
            .elements(self)
            .iter()
            .map(|m| self.parse_item_struct_member(m.clone()))
            .collect()
    }
    fn parse_item_struct_member(&self, member_ast: ast::Member) -> Member {
        Member {
            visibility: self.parse_visibility(member_ast.visibility(self)),
            name: member_ast.name(self).text(self).to_string(),
            ty: self.parse_expr(&member_ast.type_clause(self).ty(self)),
            ast: member_ast,
        }
    }

    fn parse_visibility(&self, visibility: ast::Visibility) -> Visibility {
        match visibility {
            ast::Visibility::Pub(_) => Visibility::Pub,
            ast::Visibility::Default(_) => Visibility::Default,
        }
    }

    fn parse_item_struct(
        &self,
        struct_ast: ItemStruct,
        diagnostics: &mut Vec<PluginDiagnostic>,
    ) -> CairoStruct {
        let name = struct_ast.name(self).text(self).to_string();
        let members = self.parse_item_struct_members(&struct_ast);
        let visibility = self.parse_visibility(struct_ast.visibility(self));
        let derives = self.extract_derive_attr_names(
            diagnostics,
            struct_ast.attributes(self).query_attr(self, "derive"),
        );
        let generic_params = self.parse_generic_params(struct_ast.generic_params(self));

        return CairoStruct {
            ast: struct_ast,
            derives,
            visibility,
            name,
            generic_params,
            members,
        };
    }

    fn parse_generic_params(
        &self,
        generic_params: ast::OptionWrappedGenericParamList,
    ) -> Vec<String> {
        match generic_params {
            ast::OptionWrappedGenericParamList::Empty(_) => vec![],
            ast::OptionWrappedGenericParamList::WrappedGenericParamList(generic_params) => {
                generic_params
                    .generic_params(self)
                    .elements(self)
                    .iter()
                    .map(|p| p.name(self).text(self).to_string())
                    .collect()
            }
        }
    }
    fn parse_attributes(&self, attrs: ast::AttributeList) -> Vec<Attribute> {
        attrs
            .attributes(self)
            .iter()
            .map(|a| Attribute {
                name: a
                    .path(self)
                    .as_syntax_node()
                    .get_text(self)
                    .trim()
                    .to_string(),
                args: a.args(self),
                ast: a,
            })
            .collect()
    }

    fn parse_item_enum(
        &self,
        enum_ast: ItemEnum,
        diagnostics: &mut Vec<PluginDiagnostic>,
    ) -> CairoEnum {
        let struct_type = enum_ast
            .name(self)
            .as_syntax_node()
            .get_text(self)
            .trim()
            .to_string();
        let variants = enum_ast
            .variants(self)
            .elements(self)
            .iter()
            .map(|v| CairoVariant {
                name: v.name(self).text(self).to_string(),
                ty: match v.type_clause(self) {
                    OptionTypeClause::Empty(_) => None,
                    OptionTypeClause::TypeClause(type_clause) => {
                        Some(self.parse_expr(&type_clause.ty(self)))
                    }
                },
            })
            .collect::<Vec<_>>();
        let attrs = self.extract_derive_attr_names(
            diagnostics,
            enum_ast.attributes(self).query_attr(self, "derive"),
        );

        return CairoEnum {
            ast: enum_ast,
            name: struct_type,
            attrs,
            variants,
            default: None,
        };
    }

    fn parse_struct(
        &self,
        parsed: &SyntaxNode,
        diagnostics: &mut Vec<PluginDiagnostic>,
    ) -> Option<CairoStruct> {
        println!("{}", print_tree(self, parsed, true, false));
        for n in parsed.descendants(self) {
            print!("{:?}", n.kind(self));
            match n.kind(self) {
                SyntaxKind::ItemStruct => {
                    return Some(self.parse_item_struct(
                        ast::ItemStruct::from_syntax_node(self, n),
                        diagnostics,
                    ));
                }
                _ => {
                    continue;
                }
            };
        }
        None
    }
    fn parse_enum(
        &self,
        parsed: &SyntaxNode,
        diagnostics: &mut Vec<PluginDiagnostic>,
    ) -> Option<CairoEnum> {
        for n in parsed.descendants(self) {
            match n.kind(self) {
                SyntaxKind::ItemEnum => {
                    return Some(
                        self.parse_item_enum(ast::ItemEnum::from_syntax_node(self, n), diagnostics),
                    );
                }
                _ => {
                    continue;
                }
            };
        }
        None
    }

    fn parse_type(&self, parsed: &SyntaxNode, diagnostics: &mut Vec<PluginDiagnostic>) {}

    fn parse_expr(&self, expr: &Expr) -> CairoTypeClause {
        match expr {
            Expr::Path(path) => {
                CairoTypeClause::Path(path.as_syntax_node().get_text(self).trim().to_string())
            }
            Expr::Tuple(tuple) => CairoTypeClause::Tuple(
                tuple
                    .expressions(self)
                    .elements(self)
                    .iter()
                    .map(|e| self.parse_expr(e))
                    .collect(),
            ),
            Expr(path) => {}
            _ => CairoTypeClause::Tuple(vec![]),
        }
    }
    fn extract_derive_attr_names(
        &self,
        diagnostics: &mut Vec<PluginDiagnostic>,
        attrs: Vec<ast::Attribute>,
    ) -> Vec<String> {
        attrs
            .iter()
            .filter_map(|attr| {
                let args = attr.clone().structurize(self).args;
                if args.is_empty() {
                    diagnostics.push(PluginDiagnostic {
                        stable_ptr: attr.stable_ptr().0,
                        message: "Expected args.".into(),
                        severity: Severity::Error,
                    });
                    None
                } else {
                    Some(args.into_iter().filter_map(|a| {
                        if let AttributeArgVariant::Unnamed(ast::Expr::Path(path)) = a.variant {
                            if let [ast::PathSegment::Simple(segment)] = &path.elements(self)[..] {
                                Some(segment.ident(self).text(self).to_string())
                            } else {
                                None
                            }
                        } else {
                            None
                        }
                    }))
                }
            })
            .flatten()
            .collect::<Vec<_>>()
    }
}
