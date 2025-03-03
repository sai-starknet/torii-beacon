use cairo_lang_defs::plugin::PluginDiagnostic;
use cairo_lang_diagnostics::Severity;
use cairo_lang_syntax::attribute::structured::{AttributeArgVariant, AttributeStructurize};
use cairo_lang_syntax::node::ast::{Attribute, Expr, ItemEnum, ItemStruct, OptionTypeClause};
use cairo_lang_syntax::node::db::SyntaxGroup;
use cairo_lang_syntax::node::helpers::QueryAttrs;
use cairo_lang_syntax::node::kind::SyntaxKind;
use cairo_lang_syntax::node::{ast, SyntaxNode, Terminal, TypedSyntaxNode};

#[derive(Clone, Debug)]
pub struct CairoStruct {
    pub ast: ItemStruct,
    pub name: String,
    pub attrs: Vec<String>,
    pub members: Vec<CairoNameType>,
}

#[derive(Clone, Debug)]
pub struct CairoEnum {
    pub ast: ItemEnum,
    pub name: String,
    pub attrs: Vec<String>,
    pub variants: Vec<CairoNameType>,
    pub default: Option<String>,
}

#[derive(Clone, Debug)]
pub struct CairoNameType {
    pub name: String,
    pub ty: CairoSubType,
}

#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub enum CairoSubType {
    Path(String),
    Tuple(Vec<CairoSubType>),
    None,
}

impl ToString for CairoSubType {
    fn to_string(&self) -> String {
        match self {
            CairoSubType::Path(path) => path.clone(),
            CairoSubType::Tuple(types) => {
                let types = types.iter().map(|t| t.to_string()).collect::<Vec<_>>();
                format!("({})", types.join(", "))
            }
            CairoSubType::None => "()".to_string(),
        }
    }
}

pub trait CairoTypeParser: SyntaxGroup + Sized {
    fn parse_item_struct(
        &self,
        struct_ast: ItemStruct,
        diagnostics: &mut Vec<PluginDiagnostic>,
    ) -> CairoStruct {
        let name = struct_ast
            .name(self)
            .as_syntax_node()
            .get_text(self)
            .trim()
            .to_string();
        let members = struct_ast
            .members(self)
            .elements(self)
            .iter()
            .map(|m| CairoNameType {
                name: m.name(self).text(self).to_string(),
                ty: self.parse_expr(&m.type_clause(self).ty(self)),
            })
            .collect::<Vec<_>>();
        let attrs = self.extract_derive_attr_names(
            diagnostics,
            struct_ast.attributes(self).query_attr(self, "derive"),
        );

        return CairoStruct {
            ast: struct_ast,
            name,
            attrs,
            members,
        };
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
            .map(|v| CairoNameType {
                name: v.name(self).text(self).to_string(),
                ty: match v.type_clause(self) {
                    OptionTypeClause::Empty(_) => CairoSubType::None,
                    OptionTypeClause::TypeClause(type_clause) => {
                        self.parse_expr(&type_clause.ty(self))
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
        for n in parsed.descendants(self) {
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

    fn parse_expr(&self, expr: &Expr) -> CairoSubType {
        match expr {
            Expr::Path(path) => {
                CairoSubType::Path(path.as_syntax_node().get_text(self).trim().to_string())
            }
            Expr::Tuple(tuple) => CairoSubType::Tuple(
                tuple
                    .expressions(self)
                    .elements(self)
                    .iter()
                    .map(|e| self.parse_expr(e))
                    .collect(),
            ),
            _ => CairoSubType::None,
        }
    }

    fn extract_derive_attr_names(
        &self,
        diagnostics: &mut Vec<PluginDiagnostic>,
        attrs: Vec<Attribute>,
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
