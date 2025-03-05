use crate::{parse_token_stream_to_syntax_file, DbSyntaxNode, Item};
use cairo_lang_defs::patcher::RewriteNode;
use cairo_lang_defs::plugin::PluginDiagnostic;
use cairo_lang_diagnostics::Severity;
use cairo_lang_macro::{derive_macro, ProcMacroResult, TokenStream};
use dojo_lang::derive_macros::introspect::{handle_introspect_enum, handle_introspect_struct};

#[derive_macro]
pub fn introspect(token_stream: TokenStream) -> ProcMacroResult {
    let mut diagnostics = vec![];
    let (file, _) = parse_token_stream_to_syntax_file(token_stream);
    let item = file.item();

    let derived = match item {
        Item::Struct(item) => handle_introspect_struct(
            item.db(),
            &mut diagnostics,
            item.typed_syntax_node().clone(),
            false,
        ),
        Item::Enum(item) => handle_introspect_enum(
            item.db(),
            &mut diagnostics,
            item.typed_syntax_node().clone(),
            false,
        ),
        _ => {
            diagnostics.push(PluginDiagnostic {
                stable_ptr: item.stable_ptr().0,
                message: "Dojo plugin doesn't support derive macros on other items than struct \
                          and enum."
                    .to_string(),
                severity: Severity::Error,
            });
            RewriteNode::Text("".to_string())
        }
    };

    let patch_builder = file.patch_builder();
    patch_builder.add_modified(derived);
    let (code, mappings) = patch_builder.build();
    ProcMacroResult::new(TokenStream::new(code))
}
