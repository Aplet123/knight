use Knight::TypedValue;

#| The Boolean class within Knight.
unit class Knight::Boolean does Knight::TypedValue[Bool, * <=> *, * == *];

#| Returns either `true` or `false`, depending on whether we are empty.
method Str(--> Str) is pure {
	$!value ?? 'true' !! 'false'
}
