#ifndef KN_VALUE_H
#define KN_VALUE_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include "string.h"

/*
 * The type that's used to represent an integer in Knight.
 */
typedef intmax_t kn_integer_t;


/*
 * The type that's used to represent boolean values in Knight.
 */
typedef bool kn_boolean_t;

// forward declare.
struct kn_ast_t;

enum kn_value_kind_t {
	KN_VT_STRING,
	KN_VT_BOOLEAN,
	KN_VT_INTEGER,
	KN_VT_NULL,
	KN_VT_AST,
};

struct kn_value_t {
	enum kn_value_kind_t kind;

	union {
		kn_boolean_t boolean;
		kn_integer_t integer;
		struct kn_string_t string;
		struct kn_ast_t *ast;
	};
};

struct kn_value_t kn_value_new_ast(struct kn_ast_t *);
struct kn_value_t kn_value_new_string(struct kn_string_t);
struct kn_value_t kn_value_new_integer(kn_integer_t);
struct kn_value_t kn_value_new_boolean(kn_boolean_t);
struct kn_value_t kn_value_new_null(void);

struct kn_string_t kn_value_to_string(const struct kn_value_t *);
kn_boolean_t kn_value_to_boolean(const struct kn_value_t *);
kn_integer_t kn_value_to_integer(const struct kn_value_t *);

struct kn_value_t kn_value_clone(const struct kn_value_t *);
void kn_value_free(struct kn_value_t *);

#endif /* KN_VALUE_H */
