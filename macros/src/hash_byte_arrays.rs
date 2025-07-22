use std::vec;

use cainome::cairo_serde::{ByteArray, CairoSerde};
use cairo_lang_macro::{inline_macro, ProcMacroResult, TokenStream};
use cairo_lang_parser::printer::print_tree;
use cairo_lang_reader::syntax_file::TerminalEndOfFile;
use cairo_lang_reader::{
    parse_token_stream_to_syntax_file, SyntaxElementTrait, TypedSyntaxElement,
};
use cairo_lang_syntax::node::ast;
use starknet::core::types::Felt;
use starknet_crypto::poseidon_hash_many;

pub fn compute_bytearray_hash(value: &str) -> Felt {
    let ba = ByteArray::from_string(value).unwrap_or_else(|_| panic!("Invalid ByteArray: {value}"));
    poseidon_hash_many(&ByteArray::cairo_serialize(&ba))
}

/// Extracts the content from a quoted string
/// Returns Ok(content) if the string starts and ends with quotes, Err otherwise
fn extract_quoted_string(input: &str) -> Result<String, &'static str> {
    let trimmed = input.trim();

    if trimmed.len() < 2 {
        return Err("String too short to be quoted");
    }

    if trimmed.starts_with('"') && trimmed.ends_with('"') {
        Ok(trimmed[1..trimmed.len() - 1].to_string())
    } else {
        Err("String is not properly quoted")
    }
}

#[inline_macro]
pub fn bytearrays_hash(token_stream: TokenStream) -> ProcMacroResult {
    // let db = SimpleParserDatabase::default();
    // let (root_node, _diagnostics) = db.parse_virtual_with_diagnostics(&token_stream);
    let (file, _) = parse_token_stream_to_syntax_file(token_stream);
    let text = file
        .eof::<TypedSyntaxElement<ast::TerminalEndOfFile>>()
        .get_child_syntax_element::<{ TerminalEndOfFile::INDEX_LEADING_TRIVIA }>()
        .get_text();
    let args: Vec<String> = text
        .trim()
        .trim_matches(|c| c == '(' || c == ')')
        .split(',')
        .map(|s| s.trim().to_string())
        .collect();

    let mut hashes: Vec<Felt> = vec![];
    for arg in args {
        let quoted_content = match extract_quoted_string(&arg) {
            Ok(quoted_content) => quoted_content,
            Err(error) => {
                // Handle non-quoted arguments or return an error
                eprintln!("Warning: Argument '{}' error: {}", arg, error);
                panic!("Invalid argument format")
            }
        };
        hashes.push(compute_bytearray_hash(&quoted_content));
    }
    let hash = poseidon_hash_many(&hashes);
    ProcMacroResult::new(TokenStream::new(format!("{:?}", hash)))
}
