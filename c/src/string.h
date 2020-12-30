#ifndef KN_STRING_H
#define KN_STRING_H

#include <stdint.h>
#include "integer.h"

/*
 * A struct that's used to manage strings within Knight.
 *
 * Because all strings are immutable in Knight, we're able to use a simple
 * reference counting scheme to determine when a string needs to be freed.
 *
 * Strings that shouldn't be reference counted (such as string literals) should
 * be passed to the `kn_string_intern` function.
 */
struct kn_string_t {
	const char *str;
	unsigned *rc;
};

/*
 * Creates an interned string.
 *
 * An interned string is one that's used internally by quest for identifiers
 * and other things that last the lifetime of the program. Any strings passed to
 * it will never be freed.
 *
 * This string should not be used directly with after passing it to this
 * function. Instead, interact with it through the struct field.
 *
 * When done using the returned value, it should be passed to `kn_string_free`
 * to prevent memory leaks.
 */
struct kn_string_t kn_string_intern(const char *);

/*
 * Creates a new string.
 *
 * This should only be called with strings that are able to be `free`d. For
 * static strings, look at `kn_string_intern`.
 *
 * This string should not be used directly with after passing it to this
 * function. Instead, interact with it through the struct field.
 *
 * When done using the returned value, it should be passed to `kn_string_free`
 * to prevent memory leaks.
 */
struct kn_string_t kn_string_new(const char *);

/*
 * Clones a string, returning a new copy of it.
 *
 * When done using the returned value, it should be passed to `kn_string_free`
 * to prevent memory leaks.
 */
struct kn_string_t kn_string_clone(const struct kn_string_t *);

/*
 * Creates a string from the given integer.
 *
 * When done using the returned value, it should be passed to `kn_string_free`
 * to prevent memory leaks.
 */
struct kn_string_t kn_string_from_integer(kn_integer_t);

/*
 * Converts the given string into an integer.
 *
 * Leading whitespace is stripped. If the first non-whitespace character is '-',
 * The resulting integer will be negative.  Then, characters are taken until a 
 * non-digit character is encountered, and the digits up to that point are
 * returned. If no digits are found, `0` is returned.
 */
kn_integer_t kn_string_to_integer(const struct kn_string_t *);

/*
 * Frees the memory associated with a string.
 *
 * This function should be called whenever a string's done being used to prevent
 * memory leaks. 
 *
 * This does nothing if the string was created via `kn_string_intern`.
 */
void kn_string_free(struct kn_string_t *);

#endif /* KN_STRING_H */