use v6.c;

use Log::Any::Definitions;

class Log::Any::Filter {
	proto method filter returns Bool { * }
}

class Log::Any::FilterBuiltIN is Log::Any::Filter {
	has Pair @.checks where .value ~~ Str | Regex;
	has %.severities = %Log::Any::Definitions::SEVERITIES;

	method filter( :$msg!, :$severity!, :$category! ) returns Bool {

		for @!checks -> $f {
			given $f.key {
				when 'severity' {
					given $f.value {
						when /^ '<=' / {
							return False unless %!severities{$f.value.substr(2)} <= %!severities{$severity};
						}
						when /^ '>=' / {
							return False unless %!severities{$f.value.substr(2)} >= %!severities{$severity};
						}
						when /^ '<' / {
							return False unless %!severities{$f.value.substr(1)} < %!severities{$severity};
						}
						when /^ '>' / {
							return False unless %!severities{$f.value.substr(1)} > %!severities{$severity};
						}
						when /^ '=' / {
							return False unless %!severities{$f.value.substr(1)} == %!severities{$severity};
						}
						when /^ '!=' / {
							return False unless %!severities{$f.value.substr(2)} !== %!severities{$severity};
						}
						default {
							note "nothing special matched";
							return False;
						}
					}
				}
				when 'category' {
					#note "checking $f.key() with $f.value().perl()";
					return False unless $category ~~ $f.value();
				}
				when 'msg' {
					#note "checking $f.key() with $f.value().perl()";
					return False unless $msg ~~ $f.value();
				}
				default {
					#note "default, oops";
					return False;
				}
			}
		}
		return True;
	}
}