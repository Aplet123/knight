#ifndef KN_AST_H
#define KN_AST_H

#include "env.h"
#include "value.h"

/*
 * The kinds of tokens that exist within Knight.
 *
 * Technically, there's only three "real" token types: values, identifiers, and
 * functions. However, for ease of use, each function is defined to be its own
 * token as well.
 *
 * The `value` and `ident` fields are exclusively used by the `KN_TT_VALUE` and
 * `KN_TT_IDENT` fields, respectively. The `args` field is used by the function
 * tokens. Arguments start from `args[0]` and count upwards to one less than the
 * arity of the function; arguments beyond that are undefined.
 *
 * With the sole exception of `KN_TT_EQL`, every function will automatically
 * convert types to the types they expect.
 */
enum kn_token_kind {
	/*
	 * A literal value---ie a `kn_value_t`.
	 */
	KN_TT_VALUE,

	/*
	 * An identifier within Knight.
	 */
	KN_TT_IDENT,

	/*
	 * A function
	 */
	KN_TT_FUNCTION
};

/*
 * The type that represents executable code within Knight.
 *
 * This type is created via `kn_ast_parse` and
 * should be disposed of via `kn_ast_free`.
 */
struct kn_ast_t {
	enum kn_token_kind kind;

	union {
		struct kn_value_t value;
		const char *ident;
		struct {
			const struct kn_function_t *function;
			struct kn_ast_t *args;
		};
	};
};




/*
 * Parse a `kn_ast_t` from an input stream.
 *
 * Aborts if the stream's empty, or no valid tokens can be parsed.
 */
struct kn_ast_t kn_ast_parse(const char **stream);

/*
 * Runs an `kn_ast_t`, returning the value associated with it.
 * 
 * If any errors occur whilst running the tree, the function will abort the
 * program with a message indicating the error.
 */
struct kn_value_t kn_ast_run(const struct kn_ast_t *ast);

/*
 * Clones an `kn_ast_t`.
 */
struct kn_ast_t kn_ast_clone(const struct kn_ast_t *ast);

/*
 * Releases all the resources the `kn_ast_t` has associated with it.
 */
void kn_ast_free(struct kn_ast_t *ast);

#endif /* KN_AST_H */