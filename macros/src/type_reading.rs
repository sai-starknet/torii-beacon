use cairo_lang_defs::patcher::PatchBuilder;
use cairo_lang_diagnostics::Diagnostics;
use cairo_lang_filesystem::span::{TextOffset, TextPosition, TextSpan, TextWidth};
use cairo_lang_macro::TokenStream;
use cairo_lang_parser::utils::SimpleParserDatabase;
use cairo_lang_parser::ParserDiagnostic;
use cairo_lang_syntax::attribute::structured::{AttributeArgVariant, AttributeStructurize};
use cairo_lang_syntax::node::db::SyntaxGroup;
use cairo_lang_syntax::node::element_list::ElementList;
use cairo_lang_syntax::node::green::GreenNode;
use cairo_lang_syntax::node::helpers::QueryAttrs;
use cairo_lang_syntax::node::kind::SyntaxKind;
use cairo_lang_syntax::node::{ast, SyntaxNode, Terminal, TypedSyntaxNode};
use smol_str::SmolStr;
use std::ops::Deref;
use std::sync::Arc;

pub trait DbAstTrait<'a> {
    fn db(&self) -> &dyn SyntaxGroup;

    fn syntax_node(&self) -> SyntaxNode;
    fn offset(&self) -> TextOffset {
        self.syntax_node().offset()
    }
    fn width(&self) -> TextWidth {
        self.syntax_node().width(self.db())
    }
    fn kind(&self) -> SyntaxKind {
        self.syntax_node().kind(self.db())
    }
    fn span(&self) -> TextSpan {
        self.syntax_node().span(self.db())
    }
    fn text(&self) -> Option<SmolStr> {
        self.syntax_node().text(self.db())
    }
    fn green_node(&self) -> Arc<GreenNode> {
        self.syntax_node().green_node(self.db())
    }
    fn span_without_trivia(&self) -> TextSpan {
        self.syntax_node().span_without_trivia(self.db())
    }
    fn position_in_parent(&self) -> Option<usize> {
        self.syntax_node().position_in_parent(self.db())
    }
    fn get_terminal_token(&self) -> Option<SyntaxNode> {
        self.syntax_node().get_terminal_token(self.db())
    }
    fn span_start_without_trivia(&self) -> TextOffset {
        self.syntax_node().span_start_without_trivia(self.db())
    }
    fn span_end_without_trivia(&self) -> TextOffset {
        self.syntax_node().span_end_without_trivia(self.db())
    }
    fn lookup_offset(&self, offset: TextOffset) -> SyntaxNode {
        self.syntax_node().lookup_offset(self.db(), offset)
    }
    fn lookup_position(&self, position: TextPosition) -> SyntaxNode {
        self.syntax_node().lookup_position(self.db(), position)
    }
    fn get_text(&self) -> String {
        self.syntax_node().get_text(self.db())
    }
    fn get_text_without_inner_commentable_children(&self) -> String {
        self.syntax_node()
            .get_text_without_inner_commentable_children(self.db())
    }
    fn get_text_without_all_comment_trivia(&self) -> String {
        self.syntax_node()
            .get_text_without_all_comment_trivia(self.db())
    }
    fn get_text_without_trivia(&self) -> String {
        self.syntax_node().get_text_without_trivia(self.db())
    }
    fn get_text_of_span(&self, span: TextSpan) -> String {
        self.syntax_node().get_text_of_span(self.db(), span)
    }
    fn patch_builder(&self) -> PatchBuilder {
        PatchBuilder::new_ex(self.db(), &self.syntax_node())
    }
}

trait IntoDbAstTrait {
    fn into_db_ast(&self) -> &dyn DbAstTrait;
}

impl<T> DbAstTrait<'_> for T
where
    T: IntoDbAstTrait,
{
    fn db(&self) -> &dyn SyntaxGroup {
        self.into_db_ast().db()
    }
    fn syntax_node(&self) -> SyntaxNode {
        self.into_db_ast().syntax_node()
    }
}

pub trait TypedNode<T: TypedSyntaxNode> {
    fn new(db: &dyn SyntaxGroup, node: T) -> Self;
}

pub struct DbAst<D, T: TypedSyntaxNode> {
    _db: D,
    pub ast: T,
}

impl<D, T: TypedSyntaxNode> DbAst<D, T> {
    pub fn new(db: D, ast: T) -> Self {
        Self { _db: db, ast }
    }
}

pub type SyntaxFile<'a> = DbAst<&'a dyn SyntaxGroup, ast::SyntaxFile>;
pub type Constant<'a> = DbAst<&'a dyn SyntaxGroup, ast::ItemConstant>;
pub type Module<'a> = DbAst<&'a dyn SyntaxGroup, ast::ItemModule>;
pub type Use<'a> = DbAst<&'a dyn SyntaxGroup, ast::ItemUse>;
pub type FreeFunction<'a> = DbAst<&'a dyn SyntaxGroup, ast::FunctionWithBody>;
pub type ExternFunction<'a> = DbAst<&'a dyn SyntaxGroup, ast::ItemExternFunction>;
pub type ExternType<'a> = DbAst<&'a dyn SyntaxGroup, ast::ItemExternType>;
pub type Trait<'a> = DbAst<&'a dyn SyntaxGroup, ast::ItemTrait>;
pub type Impl<'a> = DbAst<&'a dyn SyntaxGroup, ast::ItemImpl>;
pub type ImplAlias<'a> = DbAst<&'a dyn SyntaxGroup, ast::ItemImplAlias>;
pub type Struct<'a> = DbAst<&'a dyn SyntaxGroup, ast::ItemStruct>;
pub type Enum<'a> = DbAst<&'a dyn SyntaxGroup, ast::ItemEnum>;
pub type TypeAlias<'a> = DbAst<&'a dyn SyntaxGroup, ast::ItemTypeAlias>;
pub type InlineMacro<'a> = DbAst<&'a dyn SyntaxGroup, ast::ItemInlineMacro>;
pub type HeaderDoc<'a> = DbAst<&'a dyn SyntaxGroup, ast::ItemHeaderDoc>;
pub type Missing<'a> = DbAst<&'a dyn SyntaxGroup, ast::ModuleItemMissing>;

pub type Member<'a> = DbAst<&'a dyn SyntaxGroup, ast::Member>;
pub type GenericParamList<'a> = DbAst<&'a dyn SyntaxGroup, ast::OptionWrappedGenericParamList>;
pub type GenericArgList<'a> = DbAst<&'a dyn SyntaxGroup, &'a ast::GenericArgList>;
pub type Variant<'a> = DbAst<&'a dyn SyntaxGroup, ast::Variant>;
pub type TyPath<'a> = DbAst<&'a dyn SyntaxGroup, ast::ExprPath>;
pub type TyTuple<'a> = DbAst<&'a dyn SyntaxGroup, ast::ExprList>;

impl<'a, T: TypedSyntaxNode> DbAstTrait<'_> for DbAst<&dyn SyntaxGroup, T> {
    fn db(&self) -> &dyn SyntaxGroup {
        self._db
    }
    fn syntax_node(&self) -> SyntaxNode {
        self.ast.as_syntax_node()
    }
}

pub enum Item<'a> {
    Constant(Constant<'a>),
    Module(Module<'a>),
    Use(Use<'a>),
    FreeFunction(FreeFunction<'a>),
    ExternFunction(ExternFunction<'a>),
    ExternType(ExternType<'a>),
    Trait(Trait<'a>),
    Impl(Impl<'a>),
    ImplAlias(ImplAlias<'a>),
    Struct(Struct<'a>),
    Enum(Enum<'a>),
    TypeAlias(TypeAlias<'a>),
    InlineMacro(InlineMacro<'a>),
    HeaderDoc(HeaderDoc<'a>),
    Missing(Missing<'a>),
}

impl<'a> Item<'a> {
    pub fn new<T>(db: &dyn SyntaxGroup, module_item: ast::ModuleItem) -> Item {
        match module_item {
            ast::ModuleItem::Constant(item) => Item::Constant(Constant::new(db, item)),
            ast::ModuleItem::Module(item) => Item::Module(Module::new(db, item)),
            ast::ModuleItem::Use(item) => Item::Use(Use::new(db, item)),
            ast::ModuleItem::FreeFunction(item) => Item::FreeFunction(FreeFunction::new(db, item)),
            ast::ModuleItem::ExternFunction(item) => {
                Item::ExternFunction(ExternFunction::new(db, item))
            }
            ast::ModuleItem::ExternType(item) => Item::ExternType(ExternType::new(db, item)),
            ast::ModuleItem::Trait(item) => Item::Trait(Trait::new(db, item)),
            ast::ModuleItem::Impl(item) => Item::Impl(Impl::new(db, item)),
            ast::ModuleItem::ImplAlias(item) => Item::ImplAlias(ImplAlias::new(db, item)),
            ast::ModuleItem::Struct(item) => Item::Struct(Struct::new(db, item)),
            ast::ModuleItem::Enum(item) => Item::Enum(Enum::new(db, item)),
            ast::ModuleItem::TypeAlias(item) => Item::TypeAlias(TypeAlias::new(db, item)),
            ast::ModuleItem::InlineMacro(item) => Item::InlineMacro(InlineMacro::new(db, item)),
            ast::ModuleItem::HeaderDoc(item) => Item::HeaderDoc(HeaderDoc::new(db, item)),
            ast::ModuleItem::Missing(item) => Item::Missing(Missing::new(db, item)),
        }
    }
}

impl<'a> IntoDbAstTrait for Item<'a> {
    fn into_db_ast(&self) -> &dyn DbAstTrait {
        match self {
            Item::Constant(item) => item,
            Item::Module(item) => item,
            Item::Use(item) => item,
            Item::FreeFunction(item) => item,
            Item::ExternFunction(item) => item,
            Item::ExternType(item) => item,
            Item::Trait(item) => item,
            Item::Impl(item) => item,
            Item::ImplAlias(item) => item,
            Item::Struct(item) => item,
            Item::Enum(item) => item,
            Item::TypeAlias(item) => item,
            Item::InlineMacro(item) => item,
            Item::HeaderDoc(item) => item,
            Item::Missing(item) => item,
        }
    }
}

pub enum Ty<'a> {
    Path(TyPath<'a>),
    Tuple(TyTuple<'a>),
}

impl IntoDbAstTrait for Ty<'_> {
    fn into_db_ast(&self) -> &dyn DbAstTrait {
        match self {
            Ty::Path(item) => item,
            Ty::Tuple(item) => item,
        }
    }
}

#[derive(Clone, Debug)]
pub enum Visibility {
    Default,
    Pub,
}

pub fn derive_attrs(db: &dyn SyntaxGroup, attr_list: ast::AttributeList) -> Vec<String> {
    attr_list
        .query_attr(db, "derive")
        .iter()
        .filter_map(|attr| {
            let args = attr.clone().structurize(db).args;
            if args.is_empty() {
                None
            } else {
                Some(args.into_iter().filter_map(|a| {
                    if let AttributeArgVariant::Unnamed(ast::Expr::Path(path)) = a.variant {
                        if let [ast::PathSegment::Simple(segment)] = &path.elements(db)[..] {
                            Some(segment.ident(db).text(db).to_string())
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

pub fn derive_token_stream_to_type(
    token_stream: TokenStream,
) -> (Item<'static>, Diagnostics<ParserDiagnostic>) {
    let db = Box::leak(Box::new(SimpleParserDatabase::default()));
    let (parsed, diagnostics) = db.parse_virtual_with_diagnostics(token_stream);
    let module_item = ast::SyntaxFile::from_syntax_node(db, parsed)
        .items(db)
        .elements(db)[0]
        .clone();
    (Item::new(db, module_item), diagnostics)
}

pub fn ty(db: &dyn SyntaxGroup, expr: ast::Expr) -> Ty {
    match expr {
        ast::Expr::Path(ast) => Ty::Path(TyPath::new(db, ast)),
        ast::Expr::Tuple(tuple) => Ty::Tuple(TyTuple::new(db, tuple.expressions(db))),
        _ => panic!("Unsupported type"),
    }
}

pub fn element_list_to_vec<
    'a,
    T: TypedSyntaxNode + Clone + 'static,
    S: Deref<Target = ElementList<T, STEP>>,
    const STEP: usize,
>(
    db: &'a dyn SyntaxGroup,
    node: S,
) -> Vec<DbAst<&'a dyn SyntaxGroup, T>> {
    node.elements(db)
        .iter()
        .map(|e: &T| DbAst::new(db, e.clone()))
        .collect()
}

impl SyntaxFile<'_> {
    pub fn items(&self) -> Vec<Item> {
        element_list_to_vec(self.db(), self.ast.items(self.db()))
    }
}

impl Struct<'_> {
    pub fn visibility(&self) -> Visibility {
        match self.ast.visibility(self.db()) {
            ast::Visibility::Pub(_) => Visibility::Pub,
            ast::Visibility::Default(_) => Visibility::Default,
        }
    }
    pub fn name(&self) -> String {
        self.ast.name(self.db()).text(self.db()).to_string()
    }
    pub fn generic_params(&self) -> GenericParamList {
        GenericParamList::new(self.db(), self.ast.generic_params(self.db()))
    }
    pub fn members(&self) -> Vec<Member> {
        element_list_to_vec(self.db(), self.ast.members(self.db()))
    }
}

impl Member<'_> {
    pub fn visibility(&self) -> Visibility {
        match self.ast.visibility(self.db()) {
            ast::Visibility::Pub(_) => Visibility::Pub,
            ast::Visibility::Default(_) => Visibility::Default,
        }
    }
    pub fn name(&self) -> String {
        self.ast.name(self.db()).text(self.db()).to_string()
    }
    pub fn ty(&self) -> Ty {
        ty(self.db(), self.ast.type_clause(self.db()).ty(self.db()))
    }
}

impl Enum<'_> {
    pub fn visibility(&self) -> Visibility {
        match self.ast.visibility(self.db()) {
            ast::Visibility::Pub(_) => Visibility::Pub,
            ast::Visibility::Default(_) => Visibility::Default,
        }
    }
    pub fn name(&self) -> String {
        self.ast.name(self.db()).text(self.db()).to_string()
    }
    pub fn generic_params(&self) -> GenericParamList {
        GenericParamList::new(self.db(), self.ast.generic_params(self.db()))
    }
    pub fn variants(&self) -> Vec<Variant> {
        element_list_to_vec(self.db(), self.ast.variants(self.db()))
    }
}
