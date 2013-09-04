Vijka
================================================================================
_A demand model/simulator for highway tolls on regional road networks_

About
--------------------------------------------------------------------------------

_Vijka_ is a simulator for analyzing and estimating the number of vehicles that
will use a highway, that is, its traffic volume.

Given a road network and and a weighted list of origin/destination trip
desires, _Vijka_ can perform the necessary demand assignments and output the
traffic volume estimates and other interesting information.

_Vijka_ is also **fast**, and has been used to run, in only a couple of minutes,
multiple scenarios (10+) of a large number of trips (each with its own cost
perception) on detailed networks (~100k nodes, ~200k links).

Interface and platforms
--------------------------------------------------------------------------------

For the time being, _Vijka_ only has a console based user interface. You open it
in a shell (terminal emulator or prompt) and interact with it via text
commands, each with a set of corresponding arguments.

It runs on many different platforms, both native and virtual.

Of the virtual platforms, it runs on both the [Neko VM](http://nekovm.org) and
the Java VM (or, more precisely, the various Java VM flavors out there). Of
these, the Java VM is recommended due to performance and scalability reasons.

_Vijka_ also runs natively on all major operating systems (Windows, Mac OSX and
Linux), being compiled through a C++ tool-chain. Not that anyone would want that,
but it should also run on mobile systems (iOS, Android)... Ideally, the native
(C++ based) binaries should be faster than the Java VM (JVM) and, therefore,
recommended for large networks. However, due mainly to garbage collector issues
(memory management) on the underlying C++ toolchain, that is not true yet.

Therefore, the amazing Hotspot Java VM (be it the Sun/Oracle one, or the OpenJDK
one for the Linux users), is still the fastest and so, the recommended
alternative. It should also be noted that the JVM actually is faster
on Linux than on Windows.

Input
--------------------------------------------------------------------------------

The various inputs for _Vijka_ may be split in two categories: network and
demand.

The network consists of a collection of nodes and links (roads connecting nodes).
Toll fares can be set on any link. Several vehicles can be defined, each with
different number of axis and with different toll fare multipliers (the fare
set on the link is only the _base_ fare). Links also have types, and for each
combination of link type and vehicle a different speed may be set.

Links can also have custom (more detailed) shapes, other than the default
start node -> finish node line segment. They can also be referenced by aliases,
and aliases and links have N:M relation.

The demand consists on a weighted list of origin/destination trip desires. Each
of its elements is associated with a particular vehicle type and can have a
different perception of costs: there are distance based costs and time based
costs (the latter ones are then divided into social and operational).

All input is done in text files, following the [Elebeta Text Table (ETT)]
(https://github.com/Elebeta/haxe-format/blob/master/doc/ett/Elebeta%20Text%20Tables%20(ETT).md)
format. This is a variation of Comma-Separated Values (CSV, [RFC 4180]
(http://tools.ietf.org/html/rfc4180)) that retains backwards compatibility but
includes additional information:

 - Separator: comma, tab, semicolon, pipe?
 - Encoding: local ISO/extended ASCII or UTF-8?
 - Mandatory column names
 - Mandatory column types (these are used by software to check that what's in a
   column is actually compatible with its definition).

Assignment
--------------------------------------------------------------------------------

The assignment is of the all-or-nothing type, and is computed as the shortest
path between origin and destination according to a generalized cost function.

Output
--------------------------------------------------------------------------------

As with other traffic assignment software, one can generate traffic volume
estimates for all (used) links. However, this is not all.

_Vijka_ was developed with a particular focus on analyzing users of a
particular road segment. Therefore, for each assigned origin/destination trip
desire a result is stored that contains all cost parts (and the resulting
generalized cost) and its complete path. Since the full path is stored, _Vijka_
can quickly and easily identify and analyze users (and non users) of a
particular link.

_Vijka_ outputs its results in the ETT format and, also, when applicable, in
GeoJSON. [GeoJSON](http://www.geojson.org/) is a subset of
[JSON](http://www.json.org/)
(a popular text based object representation format) used for sharing geospacial
information, that can be easily parsed, converted to other formats such as
shapefiles (using [ogr2ogr](http://www.gdal.org/ogr2ogr.html)) and viewed (using
[Quantum GIS](http://www.qgis.org/), [TileMill](http://www.mapbox.com/tilemill/),
or even
[GitHub itself](https://help.github.com/articles/mapping-geojson-files-on-github) ).

Other features
--------------------------------------------------------------------------------

_Vijka_ has some additional features...

For instance, you can select and edit a group of links in the (distance based)
shortest path between two points. This sometimes saves you from having to
manually select several hundred links.

There are also features for batch runs and corresponding results storage,
but these still are somewhat primitive: you can save and execute a series of
commands from a text file (but there is no support for variables or control
statements yet) and you can also save and recall results for multiple
(different) runs.

Implementation details
--------------------------------------------------------------------------------

_Vijka_ is entirely coded in [Haxe](http://haxe.org), a open-source
cross-platform programming language and toolkit under active development.

The Haxe programming language is a high-level procedural and object oriented
language, with EcmaScript like syntax and that has also inhered a few
improvements from functional languages. It is strictly typed (so it has a lot of
compile time checks, unlike Python), but has generics (unlike C) and real
runtime Dynamics (unlike C++). It is also less verbose, easier to read, write
and maintain than languages like Java or C++. Of the functional like
improvements, it supports function binding, function passing, Lambda calculus
and pattern matching. Haxe is used to target both native (desktop C++, iOS,
Android, ...) and virtual (Neko VM, Java VM, JavaScript, Flash, ...) targets,
although some code refactoring is sometimes needed due to incompatibilities
between the underlying platforms.

Dependencies
--------------------------------------------------------------------------------

Haxe libraries necessary for compilation:
 - [elebeta-format](https://github.com/Elebeta/haxe-format) (1.0.0): for ETT and
   CSV readers and writers
 - [mcli](https://github.com/waneck/mcli) ([dev]
   (https://github.com/jonasmalacofilho/mcli/commit/60527d9cfd5cf23e1c55b23b63cc2f1ebead862a)):
   for command processing
 - [hscript](https://github.com/HaxeFoundation/hscript) (2.0.1): for the query
   engine

Development history
--------------------------------------------------------------------------------

_Vijka_ was created for a highway concession study, and version 1.0 was aimed to
provide only the most important functionality.

Initially not a concern, performance ended up getting a lot of importance when
GC issues were found on C++ Haxe target. In the next two days, the migration to
the (at time thought to be yet experimental) Java target and several algorithm
optimizations generated a 2000x speed improvement. A few days later, another
3~4x improvement was experienced by implementing concurrent computation.

Future plans
--------------------------------------------------------------------------------

In addition to general improvements on functionality and performance, there are
a few major changes that may get implemented in the following months:

 - A simple GUI interface
 - A self-contained network viewer and editor

Other than this, most of the code will be unit tested and documented soon.

Creating a generic traffic simulator was never a goal for _Vijka_, but it may
end up being its natural evolution.
