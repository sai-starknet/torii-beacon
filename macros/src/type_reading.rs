use cairo_lang_defs::patcher::PatchBuilder;
use cairo_lang_diagnostics::Diagnostics;
use cairo_lang_filesystem::span::{TextOffset, TextPosition, TextSpan, TextWidth};
use cairo_lang_macro::TokenStream;
use cairo_lang_parser::utils::SimpleParserDatabase;
use cairo_lang_parser::ParserDiagnostic;
use cairo_lang_syntax::attribute::structured::{AttributeArgVariant, AttributeStructurize};
use cairo_lang_syntax::node::db::SyntaxGroup;
use cairo_lang_syntax::node::element_list::ElementList as AstElementList;
use cairo_lang_syntax::node::green::GreenNode;
use cairo_lang_syntax::node::helpers::QueryAttrs;
use cairo_lang_syntax::node::kind::SyntaxKind;
use cairo_lang_syntax::node::{ast, SyntaxNode, Terminal, TypedStablePtr, TypedSyntaxNode};
use smol_str::SmolStr;
use std::ops::Deref;
use std::sync::Arc;

pub trait NewDbSyntaxNode<'a> {
    type TSN: TypedSyntaxNode;
    fn new(db: &'a dyn SyntaxGroup, node: Self::TSN) -> Self;
}

pub trait DbSyntaxNode<'a> {
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

pub trait DbTypedSyntaxNode<'a>: DbSyntaxNode<'a> {
    type TSN: TypedSyntaxNode;
    fn typed_syntax_node(&self) -> Self::TSN;
    fn missing(&self) -> <Self::TSN as TypedSyntaxNode>::Green {
        Self::TSN::missing(self.db())
    }
    fn stable_ptr(&self) -> <Self::TSN as TypedSyntaxNode>::StablePtr {
        self.typed_syntax_node().stable_ptr()
    }
}

pub trait DynDbSyntaxNode<'a> {
    fn to_dyn_db_ast_trait(&self) -> &dyn DbSyntaxNode;
}

impl<'a, T> DbSyntaxNode<'a> for T
where
    T: DynDbSyntaxNode<'a>,
{
    fn db(&self) -> &dyn SyntaxGroup {
        self.to_dyn_db_ast_trait().db()
    }
    fn syntax_node(&self) -> SyntaxNode {
        self.to_dyn_db_ast_trait().syntax_node()
    }
}

//////////////////////////// Typed Syntax Nodes ////////////////////////////

pub struct DbAst<'a, T: TypedSyntaxNode> {
    _db: &'a dyn SyntaxGroup,
    pub ast: T,
}

impl<'a, TSN: TypedSyntaxNode + Clone> DbAst<'a, TSN> {
    pub fn typed_syntax_node(&self) -> TSN {
        self.ast.clone()
    }
}

impl<'a, TSN: TypedSyntaxNode + Clone> DbTypedSyntaxNode<'a> for DbAst<'a, TSN> {
    type TSN = TSN;
    fn typed_syntax_node(&self) -> Self::TSN {
        self.ast.clone()
    }
}

impl<'a, T: TypedSyntaxNode> DbSyntaxNode<'a> for DbAst<'a, T> {
    fn db(&self) -> &dyn SyntaxGroup {
        self._db
    }
    fn syntax_node(&self) -> SyntaxNode {
        self.ast.as_syntax_node()
    }
}

impl<'a, TSN: TypedSyntaxNode> NewDbSyntaxNode<'a> for DbAst<'a, TSN> {
    type TSN = TSN;
    fn new(db: &'a dyn SyntaxGroup, node: Self::TSN) -> Self {
        Self { _db: db, ast: node }
    }
}

pub type SyntaxFile<'a> = DbAst<'a, ast::SyntaxFile>;

pub type Constant<'a> = DbAst<'a, ast::ItemConstant>;
pub type Module<'a> = DbAst<'a, ast::ItemModule>;
pub type Use<'a> = DbAst<'a, ast::ItemUse>;
pub type FreeFunction<'a> = DbAst<'a, ast::FunctionWithBody>;
pub type ExternFunction<'a> = DbAst<'a, ast::ItemExternFunction>;
pub type ExternType<'a> = DbAst<'a, ast::ItemExternType>;
pub type Trait<'a> = DbAst<'a, ast::ItemTrait>;
pub type Impl<'a> = DbAst<'a, ast::ItemImpl>;
pub type ImplAlias<'a> = DbAst<'a, ast::ItemImplAlias>;
pub type Struct<'a> = DbAst<'a, ast::ItemStruct>;
pub type Enum<'a> = DbAst<'a, ast::ItemEnum>;
pub type TypeAlias<'a> = DbAst<'a, ast::ItemTypeAlias>;
pub type InlineMacro<'a> = DbAst<'a, ast::ItemInlineMacro>;
pub type ItemHeaderDoc<'a> = DbAst<'a, ast::ItemHeaderDoc>;
pub type ItemMissing<'a> = DbAst<'a, ast::ModuleItemMissing>;

pub type Member<'a> = DbAst<'a, ast::Member>;
pub type GenericParamList<'a> = DbAst<'a, ast::OptionWrappedGenericParamList>;
pub type GenericArgList<'a> = DbAst<'a, &'a ast::GenericArgList>;
pub type Variant<'a> = DbAst<'a, ast::Variant>;

// pub type TyPath<'a> = DbAst<'a, ast::ExprPath>;
// pub type TyTuple<'a> = DbAst<'a, ast::ExprList>;

pub type Path<'a> = DbAst<'a, ast::ExprPath>;
pub type Literal<'a> = DbAst<'a, ast::TerminalLiteralNumber>;
pub type ShortString<'a> = DbAst<'a, ast::TerminalShortString>;
pub type ExprString<'a> = DbAst<'a, ast::TerminalString>;
pub type False<'a> = DbAst<'a, ast::TerminalFalse>;
pub type True<'a> = DbAst<'a, ast::TerminalTrue>;
pub type Parenthesized<'a> = DbAst<'a, ast::ExprParenthesized>;
pub type Unary<'a> = DbAst<'a, ast::ExprUnary>;
pub type Binary<'a> = DbAst<'a, ast::ExprBinary>;
pub type Tuple<'a> = DbAst<'a, ast::ExprList>;
pub type FunctionCall<'a> = DbAst<'a, ast::ExprFunctionCall>;
pub type StructCtorCall<'a> = DbAst<'a, ast::ExprStructCtorCall>;
pub type Block<'a> = DbAst<'a, ast::ExprBlock>;
pub type Match<'a> = DbAst<'a, ast::ExprMatch>;
pub type If<'a> = DbAst<'a, ast::ExprIf>;
pub type Loop<'a> = DbAst<'a, ast::ExprLoop>;
pub type While<'a> = DbAst<'a, ast::ExprWhile>;
pub type For<'a> = DbAst<'a, ast::ExprFor>;
pub type Closure<'a> = DbAst<'a, ast::ExprClosure>;
pub type ErrorPropagate<'a> = DbAst<'a, ast::ExprErrorPropagate>;
pub type FieldInitShorthand<'a> = DbAst<'a, ast::ExprFieldInitShorthand>;
pub type Indexed<'a> = DbAst<'a, ast::ExprIndexed>;
pub type ExprInlineMacro<'a> = DbAst<'a, ast::ExprInlineMacro>;
pub type FixedSizeArray<'a> = DbAst<'a, ast::ExprFixedSizeArray>;
pub type ExprMissing<'a> = DbAst<'a, ast::ExprMissing>;

////////////////// Items //////////////////

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
    HeaderDoc(ItemHeaderDoc<'a>),
    Missing(ItemMissing<'a>),
}

pub fn element_list_to_vec<
    'a,
    TSN: TypedSyntaxNode + Clone,
    T: NewDbSyntaxNode<'a, TSN = TSN>,
    S: Deref<Target = AstElementList<TSN, STEP>>,
    const STEP: usize,
>(
    db: &'a dyn SyntaxGroup,
    node: S,
) -> Vec<T> {
    node.elements(db)
        .iter()
        .map(|e: &TSN| T::new(db, e.clone()))
        .collect()
}

impl<'a> DynDbSyntaxNode<'a> for Item<'a> {
    fn to_dyn_db_ast_trait(&self) -> &dyn DbSyntaxNode {
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

impl<'a> NewDbSyntaxNode<'a> for Item<'a> {
    type TSN = ast::ModuleItem;
    fn new(db: &'a dyn SyntaxGroup, node: ast::ModuleItem) -> Self {
        match node {
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
            ast::ModuleItem::HeaderDoc(item) => Item::HeaderDoc(ItemHeaderDoc::new(db, item)),
            ast::ModuleItem::Missing(item) => Item::Missing(ItemMissing::new(db, item)),
        }
    }
}

impl<'a> DbTypedSyntaxNode<'a> for Item<'a> {
    type TSN = ast::ModuleItem;
    fn typed_syntax_node(&self) -> Self::TSN {
        ast::ModuleItem::from_syntax_node(self.db(), self.syntax_node())
    }
}

////////////////// Expressions //////////////////

pub enum Expression<'a> {
    Path(Path<'a>),
    Literal(Literal<'a>),
    ShortString(ShortString<'a>),
    String(ExprString<'a>),
    False(False<'a>),
    True(True<'a>),
    Parenthesized(Parenthesized<'a>),
    Unary(Unary<'a>),
    Binary(Binary<'a>),
    Tuple(Tuple<'a>),
    FunctionCall(FunctionCall<'a>),
    StructCtorCall(StructCtorCall<'a>),
    Block(Block<'a>),
    Match(Match<'a>),
    If(If<'a>),
    Loop(Loop<'a>),
    While(While<'a>),
    For(For<'a>),
    Closure(Closure<'a>),
    ErrorPropagate(ErrorPropagate<'a>),
    FieldInitShorthand(FieldInitShorthand<'a>),
    Indexed(Indexed<'a>),
    InlineMacro(ExprInlineMacro<'a>),
    FixedSizeArray(FixedSizeArray<'a>),
    Missing(ExprMissing<'a>),
}

impl<'a> DynDbSyntaxNode<'a> for Expression<'a> {
    fn to_dyn_db_ast_trait(&self) -> &dyn DbSyntaxNode {
        match self {
            Expression::Path(expr) => expr,
            Expression::Literal(expr) => expr,
            Expression::ShortString(expr) => expr,
            Expression::String(expr) => expr,
            Expression::False(expr) => expr,
            Expression::True(expr) => expr,
            Expression::Parenthesized(expr) => expr,
            Expression::Unary(expr) => expr,
            Expression::Binary(expr) => expr,
            Expression::Tuple(expr) => expr,
            Expression::FunctionCall(expr) => expr,
            Expression::StructCtorCall(expr) => expr,
            Expression::Block(expr) => expr,
            Expression::Match(expr) => expr,
            Expression::If(expr) => expr,
            Expression::Loop(expr) => expr,
            Expression::While(expr) => expr,
            Expression::For(expr) => expr,
            Expression::Closure(expr) => expr,
            Expression::ErrorPropagate(expr) => expr,
            Expression::FieldInitShorthand(expr) => expr,
            Expression::Indexed(expr) => expr,
            Expression::InlineMacro(expr) => expr,
            Expression::FixedSizeArray(expr) => expr,
            Expression::Missing(expr) => expr,
        }
    }
}

impl<'a> NewDbSyntaxNode<'a> for Expression<'a> {
    type TSN = ast::Expr;
    fn new(db: &'a dyn SyntaxGroup, node: ast::Expr) -> Expression<'a> {
        match node {
            ast::Expr::Path(expr) => Expression::Path(Path::new(db, expr)),
            ast::Expr::Literal(expr) => Expression::Literal(Literal::new(db, expr)),
            ast::Expr::ShortString(expr) => Expression::ShortString(ShortString::new(db, expr)),
            ast::Expr::String(expr) => Expression::String(ExprString::new(db, expr)),
            ast::Expr::False(expr) => Expression::False(False::new(db, expr)),
            ast::Expr::True(expr) => Expression::True(True::new(db, expr)),
            ast::Expr::Parenthesized(expr) => {
                Expression::Parenthesized(Parenthesized::new(db, expr))
            }
            ast::Expr::Unary(expr) => Expression::Unary(Unary::new(db, expr)),
            ast::Expr::Binary(expr) => Expression::Binary(Binary::new(db, expr)),
            ast::Expr::Tuple(expr) => Expression::Tuple(Tuple::new(db, expr.expressions(db))),
            ast::Expr::FunctionCall(expr) => Expression::FunctionCall(FunctionCall::new(db, expr)),
            ast::Expr::StructCtorCall(expr) => {
                Expression::StructCtorCall(StructCtorCall::new(db, expr))
            }
            ast::Expr::Block(expr) => Expression::Block(Block::new(db, expr)),
            ast::Expr::Match(expr) => Expression::Match(Match::new(db, expr)),
            ast::Expr::If(expr) => Expression::If(If::new(db, expr)),
            ast::Expr::Loop(expr) => Expression::Loop(Loop::new(db, expr)),
            ast::Expr::While(expr) => Expression::While(While::new(db, expr)),
            ast::Expr::For(expr) => Expression::For(For::new(db, expr)),
            ast::Expr::Closure(expr) => Expression::Closure(Closure::new(db, expr)),
            ast::Expr::ErrorPropagate(expr) => {
                Expression::ErrorPropagate(ErrorPropagate::new(db, expr))
            }
            ast::Expr::FieldInitShorthand(expr) => {
                Expression::FieldInitShorthand(FieldInitShorthand::new(db, expr))
            }
            ast::Expr::Indexed(expr) => Expression::Indexed(Indexed::new(db, expr)),
            ast::Expr::InlineMacro(expr) => Expression::InlineMacro(ExprInlineMacro::new(db, expr)),
            ast::Expr::FixedSizeArray(expr) => {
                Expression::FixedSizeArray(FixedSizeArray::new(db, expr))
            }
            ast::Expr::Missing(expr) => Expression::Missing(ExprMissing::new(db, expr)),
        }
    }
}

impl<'a> DbTypedSyntaxNode<'a> for Expression<'a> {
    type TSN = ast::Expr;
    fn typed_syntax_node(&self) -> Self::TSN {
        ast::Expr::from_syntax_node(self.db(), self.syntax_node())
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

pub fn parse_token_stream_to_syntax_file(
    token_stream: TokenStream,
) -> (SyntaxFile<'static>, Diagnostics<ParserDiagnostic>) {
    let db = Box::leak(Box::new(SimpleParserDatabase::default()));
    let (parsed, diagnostics) = db.parse_virtual_with_diagnostics(token_stream);
    let syntax_file = ast::SyntaxFile::from_syntax_node(db, parsed);
    (SyntaxFile::new(db, syntax_file), diagnostics)
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

// pub fn ty(db: &dyn SyntaxGroup, expr: ast::Expr) -> Ty {
//     match expr {
//         ast::Expr::Path(ast) => Ty::Path(TyPath::new(db, ast)),
//         ast::Expr::Tuple(tuple) => Ty::Tuple(TyTuple::new(db, tuple.expressions(db))),
//         _ => panic!("Unsupported type"),
//     }
// }

impl SyntaxFile<'_> {
    pub fn items(&self) -> Vec<Item> {
        element_list_to_vec(self.db(), self.ast.items(self.db()))
    }
    pub fn item(&self) -> Item {
        Item::new(
            self.db(),
            self.ast
                .items(self.db())
                .elements(self.db())
                .iter()
                .next()
                .unwrap()
                .clone(),
        )
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
        let list = self.ast.members(self.db());
        element_list_to_vec(self.db(), list)
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
    pub fn ty(&self) -> Expression {
        Expression::new(self.db(), self.ast.type_clause(self.db()).ty(self.db()))
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
