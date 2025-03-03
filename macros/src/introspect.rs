use cairo_lang_macro::{derive_macro, ProcMacroResult, TokenStream};
use dojo_lang::*;

#[derive_macro]
pub fn introspect(token_stream: TokenStream) -> ProcMacroResult {}
