# NAME

Log::Any

# SYNOPSIS

```perl6
use Log::Any::Adapter::File;
Log.add( Log::Any::Adapter::File.new( '/path/to/file.log' ) );

use Log::Any;
Log.info( 'yolo' );
Log.error( :category('security'), 'oups' );
Log.log( :msg('msg from app'), :category( 'network' ), :severity( 'info' ) );
```

# DESCRIPTION

Log::Any is a library to generate and handle application logs.
A log is a message indicating an application status in a moment in time. It has attributes, like a _severity_ (error, warning, debug, …), a _category_, a _date_ and a _message_.

These attributes are used by the "Formatter" to format the log and can also be used to filter logs and to choose where the log will be handled (via Adapters).

## SEVERITY

The severity is the level of urgence of a log.
It can take the following values:
- emergency
- alert
- critical
- error
- warning
- notice
- info
- debug
- trace

TODO:
Idealy, the severity levels should be specifiable while creating the log system, because some users would need some other severity order.
```perl6
Log::Any.severities( [ 'level1', 'level2', … ] );
```

## CATEGORY

The category allows to classify them.

_Default value_ : the package name where the log is generated.

## DATE

The date is generated by Log::Any, and its values is the current date and time (ISO 8601).

## MESSAGE

A message is a string passed to Log::Any defined by the user.
TODO: Proxies to log more than a string (or use formatter?).

# ADAPTERS

An adapter handles a log by storing it, or sending it elsewhere.
If no adapters are defined, or no one meets the filtering, the message will not be logged.

A few examples:

- Log::Any::Adapter::File
- Log::Any::Adapter::Database::SQL
- Log::Any::Adapter::STDOUT

## FORMATTERS

Often, logs need to be formatted to simplify the storage (time-series databases), or the analysis (grep, log parser).
Formatters are just a string which defines the log format.

Formatters will use the attributes of a Log.

|Symbol|Signification|Description                                  |Default value             |
|------|-------------|---------------------------------------------|--------------------------|
|\\d   |Date (UTC)   |The date on which the log was generated      |Current date time         |
|\\c   |Category     |Can be any anything specified by the user    |The current package/module|
|\\s   |Severity     |Indicates if it's an information, or an error| none                     |
|\\m   |Message      |Payload, explains what is going on           | none                     |

```perl6
use Log::Any::Adapter::STDOUT( :formatter( '\d \c \m' ) );
```

You can of course use variables in the formatter, but since _\\_ is already used in Perl6 strings interpolation, you have to escape them.

```perl6
my $prefix = 'myapp ';
use Log::Any::Adapter::STDOUT( :format( "$prefix \\d \\c \\s \\m" ) );
```

TODO:
An adapter can define a prefered formatter which will be used if no formatter are specified.

## FILTERS

Filters can be used to allow a log to be handled by an adapter.
Many fields can be filtered, like the category, the severity or the message.

The easiest way to define a filter is by using the _filter_ parameter of Log::Any.log method.

```perl6
Log::Any.add( Adapter.new, :filter( [ <filters fields goes here>] ) );
```

Filtering on category or message:
```perl6
# Matching by String
Log::Any.add( Adapter.new, :filter( ['category' => 'My::Wonderfull::Lib' ] ) );
# Matching by Regex
Log::Any.add( Adapter.new, :filter( ['category' => /My::*::Lib/, 'severity' => '>warning' ] ) );

# Matching msg by Regex
Log::Any.add( Adapter.new, :filter( [ 'msg' => /a regex/ ] );
```

Filtering on severity:

/!\ Work in progress /!\

The severity can be considered as levels, so can be traited as numbers.

1. trace
2. debug
3. info
4. notice
5. warning
6. error
7. critical
8. alert
9. emergency

This is a work in progress, the idea is to use a comparaison operator:
```perl6
filter => [ 'severity' => '>warning' ] # Above
filter => [ 'severity' => '==debug'  ] # Equality
filter => [ 'severity' => '<notice'  ] # Beside
filter => [ 'severity' => [ 'notice', 'warning' ] ]
filter => [ 'severity' => [ * - 'warning' ] ] # All but 'warning'
```

If several filters are specified, all must be valid

```perl6
# Use this adapter only if the category is My::Wonderfull::Lib and if the severity is warning or error
[ 'severity' => '>=warning', 'category' => /My::Wonderfull::Lib/ ]
```

If a more complex filtering is necessary, a class can be created:
```perl6
# Use home-made filters
class MyOwnFilter is Log::Any::Filter {
	method filter( :$msg, :$severity, :$category ) returns Bool {
		# Write some complicated tests
		return True;
	}
}
my $f = Filter.new
Log::Any.add( Some::Adapter.new, :filter( $f ) );
```

### Filters acting like barrier

/!\ Work in progress /!\

```perl6
Log::Any.add( Adapter.new );
Log::Any.add( :filter( [ severity => '>warning' ] );
# Only logs with severity above _warning_ continues through the pipeline.
Log::Any.add( Adapter2.new );
```

# PIPELINES

A _pipeline_ is a set of Adapters and can be used to define alternatives path (a set of adapters, filters, formatters and options (asynchronicity) ). This allows to handle differently some logs (for example, for security or realtime).
If a log is produced with a specific facility which is not defined in the log consumers, the default facility is used.

Pipelines can be specified when an Adapter is added.
```perl6
Log::Any.add( :pipeline('security'), Log::Any::Adapter::Example.new );

Log::Any.error( :pipeline('security'), :msg('security error!', ... ) );
```

# EXTRA FEATURES

## Exporting aliases

Can be usefull to use more consise routines :

```perl6
use Log::Any( :subs );

log-adapt( Adapter.new );

warning( 'missing some configuration' );
critical( 'a big problem occured' );
```

## Wrapping

### STDOUT, STDERR

Sometimes, applications or libraries are already available, and prints their logs to STDOUT and/or STDERR. Log::Any could captures these logs and manage them.

### EXCEPTIONS

Catches all unhandled exceptions to log them.

## Stacktrace

Dump a stacktrace with the log. This could be usefull to find a problem.
	Is it necessary?
	Is it possible to do in an Adapter or some Proxy ?

## Asynchronicity

```perl6
use Log::Any ( :async );

Log::Any.pipeline( 'myapp' ).async( True );
```

## log-on-error

keep in cache logs in streams (all, from trace to info)
	- if an error occurs (how to detect, using a level?), log the stacktrace ;
	- if nothing special occurs, log cached logs as specified in the filters.

## Load log configuration from configuration files

- with a watcher on the file ?
	- pause dispatching during the reload ;

## PROXYs

A proxy is a class used to intercept messages before they are relly sent to the log subroutine. They can be usefull to log more than strings, or to analyse the message. They can also add some data in the message like tags.
	todo: is a filter, a proxy?

## INTROSPECTION

- Print a pipeline
- check if a log will be handled (to prevent computation of log) ;
```perl6
Log::Any.debug( serialize( $some-complex-object ) ) if Log::Any.will-log;
```
It's not faisable if the filter applies on the message…

## TAGS

Where?
	- in place of category ?
	- as extended intormations ? +1
How?
	- tags: [ tag1, tag2 ]
	- how to log them (array) ?

